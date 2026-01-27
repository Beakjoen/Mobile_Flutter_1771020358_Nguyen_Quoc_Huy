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
    public class BookingsController : ControllerBase
    {
        private readonly PcmDbContext _context;
        private readonly IHubContext<PcmHub> _hubContext;

        public BookingsController(PcmDbContext context, IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        [HttpGet("calendar")]
        public async Task<ActionResult<IEnumerable<Booking>>> GetCalendar(DateTime from, DateTime to)
        {
            return await _context.Bookings
                .Where(b => b.StartTime >= from && b.EndTime <= to && b.Status != BookingStatus.Cancelled)
                .Include(b => b.Member)
                .Include(b => b.Court)
                .ToListAsync();
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> CreateBooking([FromBody] BookingRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized("Không tìm thấy thông tin thành viên");

            // Check overlap
            bool isOverlapping = await _context.Bookings.AnyAsync(b =>
                b.CourtId == request.CourtId &&
                b.Status != BookingStatus.Cancelled &&
                ((request.StartTime >= b.StartTime && request.StartTime < b.EndTime) ||
                 (request.EndTime > b.StartTime && request.EndTime <= b.EndTime) ||
                 (request.StartTime <= b.StartTime && request.EndTime >= b.EndTime)));

            if (isOverlapping) return BadRequest("Khung giờ này đã có người đặt");

            var court = await _context.Courts.FindAsync(request.CourtId);
            if (court == null) return BadRequest("Sân không hợp lệ");

            // Calculate price
            var duration = (request.EndTime - request.StartTime).TotalHours;
            var totalPrice = (decimal)duration * court.PricePerHour;

            // Check wallet
            if (member.WalletBalance < totalPrice) return BadRequest("Số dư ví không đủ");

            using var transaction = _context.Database.BeginTransaction();
            try
            {
                // Create wallet transaction
                var walletTx = new WalletTransaction
                {
                    MemberId = member.Id,
                    Amount = -totalPrice,
                    Type = TransactionType.Payment,
                    Status = TransactionStatus.Completed,
                    Description = $"Thanh toán đặt sân {court.Name}",
                    CreatedDate = DateTime.Now
                };
                _context.WalletTransactions.Add(walletTx);
                
                member.WalletBalance -= totalPrice;
                member.TotalSpent += totalPrice;

                await _context.SaveChangesAsync(); // Save to get ID

                var booking = new Booking
                {
                    CourtId = request.CourtId,
                    MemberId = member.Id,
                    StartTime = request.StartTime,
                    EndTime = request.EndTime,
                    TotalPrice = totalPrice,
                    TransactionId = walletTx.Id,
                    Status = BookingStatus.Confirmed
                };

                _context.Bookings.Add(booking);
                await _context.SaveChangesAsync();
                
                walletTx.RelatedId = booking.Id.ToString();
                // Ensure the transaction is updated with RelatedId
                _context.Entry(walletTx).State = EntityState.Modified; 
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();

                // SignalR update
                await _hubContext.Clients.All.SendAsync("UpdateCalendar", "Đã có người đặt sân mới");

                return Ok(booking);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, ex.Message);
            }
        }
        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> CancelBooking(int id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized("Không tìm thấy thông tin thành viên");

            var booking = await _context.Bookings
                .Include(b => b.Court)
                .FirstOrDefaultAsync(b => b.Id == id);

            if (booking == null) return NotFound("Không tìm thấy lịch đặt");
            if (booking.MemberId != member.Id) return Forbid("Bạn không có quyền hủy lịch này");
            if (booking.Status == BookingStatus.Cancelled) return BadRequest("Lịch đặt đã bị hủy trước đó");

            // Refund logic: Full refund if cancelled > 24h before
            // For demo: Always full refund
            
            using var transaction = _context.Database.BeginTransaction();
            try
            {
                booking.Status = BookingStatus.Cancelled;
                
                var walletTx = new WalletTransaction
                {
                    MemberId = member.Id,
                    Amount = booking.TotalPrice,
                    Type = TransactionType.Refund,
                    Status = TransactionStatus.Completed,
                    Description = $"Hoàn tiền hủy đặt sân {booking.Court?.Name}",
                    CreatedDate = DateTime.Now,
                    RelatedId = booking.Id.ToString()
                };
                
                _context.WalletTransactions.Add(walletTx);
                member.WalletBalance += booking.TotalPrice;
                member.TotalSpent -= booking.TotalPrice; // Optional: Adjust spent or not

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                await _hubContext.Clients.All.SendAsync("UpdateCalendar", "Lịch đặt sân đã bị hủy");

                return Ok(new { message = "Hủy lịch thành công", refundAmount = booking.TotalPrice });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, ex.Message);
            }
        }
    }

    public class BookingRequest
    {
        public int CourtId { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
    }
}
