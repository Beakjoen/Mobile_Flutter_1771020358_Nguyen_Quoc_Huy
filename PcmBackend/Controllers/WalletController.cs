using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Hubs;
using PcmBackend.Models;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class WalletController : ControllerBase
    {
        private readonly PcmDbContext _context;
        private readonly IHubContext<PcmHub> _hubContext;

        public WalletController(PcmDbContext context, IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        [HttpPost("deposit")]
        public async Task<IActionResult> Deposit([FromBody] DepositRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return NotFound();

            var transaction = new WalletTransaction
            {
                MemberId = member.Id,
                Amount = request.Amount,
                Type = TransactionType.Deposit,
                Status = TransactionStatus.Pending, // Changed to Pending for Admin Approval
                Description = "Nạp tiền vào ví (Chờ duyệt)",
                CreatedDate = DateTime.Now
            };

            _context.WalletTransactions.Add(transaction);
            // Balance is NOT updated here. It will be updated upon approval.

            await _context.SaveChangesAsync();

            return Ok(transaction);
        }

        [HttpGet("pending-deposits")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<IEnumerable<dynamic>>> GetPendingDeposits()
        {
            return await _context.WalletTransactions
                .Where(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Pending)
                .Include(t => t.Member)
                .Select(t => new {
                    t.Id,
                    t.Amount,
                    t.CreatedDate,
                    t.Description,
                    MemberName = t.Member.FullName,
                    MemberId = t.MemberId
                })
                .OrderByDescending(t => t.CreatedDate)
                .ToListAsync();
        }

        // Admin only
        [HttpPut("approve/{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> ApproveDeposit(int id)
        {
            var transaction = await _context.WalletTransactions.FindAsync(id);
            if (transaction == null) return NotFound();

            if (transaction.Status != TransactionStatus.Pending)
                return BadRequest("Giao dịch đã được xử lý");

            transaction.Status = TransactionStatus.Completed;
            transaction.Description = "Nạp tiền vào ví (Thành công)";

            var member = await _context.Members.FindAsync(transaction.MemberId);
            if (member != null)
            {
                member.WalletBalance += transaction.Amount;
            }

            await _context.SaveChangesAsync();

            // Notify user via SignalR (Placeholder)
            // if (member?.UserId != null) await _hubContext.Clients.User(member.UserId).SendAsync("ReceiveNotification", ...);

            return Ok(transaction);
        }

        [HttpPut("reject/{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> RejectDeposit(int id)
        {
            var transaction = await _context.WalletTransactions.FindAsync(id);
            if (transaction == null) return NotFound();

            if (transaction.Status != TransactionStatus.Pending)
                return BadRequest("Giao dịch đã được xử lý");

            transaction.Status = TransactionStatus.Rejected;
            transaction.Description = "Nạp tiền vào ví (Bị từ chối)";

            await _context.SaveChangesAsync();

            return Ok(transaction);
        }
    }

    public class DepositRequest
    {
        public decimal Amount { get; set; }
        public string? ImageUrl { get; set; }
    }
}
