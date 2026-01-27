using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin,Treasurer")]
    public class AdminController : ControllerBase
    {
        private readonly PcmDbContext _context;

        public AdminController(PcmDbContext context)
        {
            _context = context;
        }

        [HttpGet("stats")]
        public async Task<IActionResult> GetDashboardStats()
        {
            var now = DateTime.Now;
            var startOfMonth = new DateTime(now.Year, now.Month, 1);
            var startOfLast6Months = now.AddMonths(-5); // Include current month

            // 1. Monthly Booking Count (Current Month)
            var currentMonthBookings = await _context.Bookings
                .CountAsync(b => b.StartTime >= startOfMonth && b.Status != BookingStatus.Cancelled);

            // 2. Revenue Chart Data (Last 6 Months)
            // Group transactions by Month/Year
            var transactions = await _context.WalletTransactions
                .Where(t => t.CreatedDate >= new DateTime(startOfLast6Months.Year, startOfLast6Months.Month, 1))
                .Select(t => new { t.Type, t.Amount, t.CreatedDate })
                .ToListAsync();

            var revenueStats = transactions
                .GroupBy(t => new { t.CreatedDate.Year, t.CreatedDate.Month })
                .Select(g => new
                {
                    Month = $"{g.Key.Month}/{g.Key.Year}",
                    // Income: Deposits
                    Income = g.Where(t => t.Type == TransactionType.Deposit).Sum(t => t.Amount),
                    // Expense: Payments (Absolute value)
                    Expense = g.Where(t => t.Type == TransactionType.Payment).Sum(t => Math.Abs(t.Amount))
                })
                .OrderBy(x => x.Month.Split('/')[1]).ThenBy(x => x.Month.Split('/')[0]) // Sort by year then month might need proper parsing
                .ToList();
            
            // Fix sorting: the string sort above is wrong. Let's do it properly.
            var revenueStatsSorted = revenueStats
                .OrderBy(x => DateTime.ParseExact(x.Month, "M/yyyy", null))
                .ToList();

            // 3. Cảnh báo quỹ âm (Admin/Treasurer) - PHẦN 1: "Quản lý dòng tiền Thu/Chi minh bạch. Cảnh báo quỹ âm"
            var negativeBalanceCount = await _context.Members.CountAsync(m => m.WalletBalance < 0);
            var lowBalanceCount = await _context.Members.CountAsync(m => m.WalletBalance >= 0 && m.WalletBalance < 500_000);

            return Ok(new
            {
                MonthlyBookings = currentMonthBookings,
                RevenueChart = revenueStatsSorted,
                NegativeBalanceCount = negativeBalanceCount,
                LowBalanceCount = lowBalanceCount,
                HasWalletWarning = negativeBalanceCount > 0 || lowBalanceCount > 0
            });
        }

        /// <summary>PHẦN 3: PUT /api/admin/wallet/approve/{transactionId} - Admin duyệt nạp tiền.</summary>
        [HttpPut("wallet/approve/{transactionId}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> ApproveWalletDeposit(int transactionId)
        {
            var wt = await _context.WalletTransactions.FindAsync(transactionId);
            if (wt == null) return NotFound();
            if (wt.Status != TransactionStatus.Pending)
                return BadRequest("Giao dịch đã được xử lý");

            wt.Status = TransactionStatus.Completed;
            wt.Description = "Nạp tiền vào ví (Thành công)";
            var member = await _context.Members.FindAsync(wt.MemberId);
            if (member != null)
            {
                member.WalletBalance += wt.Amount;
                member.TotalDeposit += wt.Amount;
                MemberTierHelper.UpdateTier(member);
            }
            await _context.SaveChangesAsync();
            return Ok(wt);
        }
    }
}
