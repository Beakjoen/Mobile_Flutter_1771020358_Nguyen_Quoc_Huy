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

        [HttpPost("hold")]
        [Authorize]
        public async Task<IActionResult> HoldBooking([FromBody] BookingRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized("Không tìm thấy thông tin thành viên");

            // Check overlap (including Holding)
            bool isOverlapping = await _context.Bookings.AnyAsync(b =>
                b.CourtId == request.CourtId &&
                b.Status != BookingStatus.Cancelled &&
                ((request.StartTime >= b.StartTime && request.StartTime < b.EndTime) ||
                 (request.EndTime > b.StartTime && request.EndTime <= b.EndTime) ||
                 (request.StartTime <= b.StartTime && request.EndTime >= b.EndTime)));

            if (isOverlapping) return BadRequest("Khung giờ này đã có người đặt hoặc đang giữ chỗ");

            var court = await _context.Courts.FindAsync(request.CourtId);
            if (court == null) return BadRequest("Sân không hợp lệ");

            var duration = (request.EndTime - request.StartTime).TotalHours;
            var totalPrice = (decimal)duration * court.PricePerHour;

            var booking = new Booking
            {
                CourtId = request.CourtId,
                MemberId = member.Id,
                StartTime = request.StartTime,
                EndTime = request.EndTime,
                TotalPrice = totalPrice,
                Status = BookingStatus.Holding,
                CreatedDate = DateTime.Now
            };

            _context.Bookings.Add(booking);
            await _context.SaveChangesAsync();

            await _hubContext.Clients.All.SendAsync("UpdateCalendar", "Có slot đang được giữ");

            return Ok(new { booking.Id, Message = "Đã giữ chỗ trong 5 phút" });
        }

        [HttpPost("confirm/{id}")]
        [Authorize]
        public async Task<IActionResult> ConfirmBooking(int id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized("Không tìm thấy thông tin thành viên");

            var booking = await _context.Bookings.FindAsync(id);
            if (booking == null) return NotFound("Không tìm thấy lịch đặt");
            
            if (booking.MemberId != member.Id) return Forbid("Bạn không phải người giữ chỗ này");
            if (booking.Status != BookingStatus.Holding) return BadRequest("Lịch này không ở trạng thái giữ chỗ");
            
            // Check timeout (double check besides background service)
            if (booking.CreatedDate.AddMinutes(5) < DateTime.Now)
            {
                booking.Status = BookingStatus.Cancelled;
                await _context.SaveChangesAsync();
                return BadRequest("Hết thời gian giữ chỗ");
            }

            // Pay
            if (member.WalletBalance < booking.TotalPrice) return BadRequest("Số dư ví không đủ");

            using var transaction = _context.Database.BeginTransaction();
            try
            {
                var walletTx = new WalletTransaction
                {
                    MemberId = member.Id,
                    Amount = -booking.TotalPrice,
                    Type = TransactionType.Payment,
                    Status = TransactionStatus.Completed,
                    Description = $"Thanh toán giữ chỗ đặt sân {booking.CourtId}", // Should fetch Court Name ideally
                    CreatedDate = DateTime.Now,
                    RelatedId = booking.Id.ToString()
                };
                _context.WalletTransactions.Add(walletTx);
                
                member.WalletBalance -= booking.TotalPrice;
                member.TotalSpent += booking.TotalPrice;

                booking.Status = BookingStatus.Confirmed;
                booking.TransactionId = walletTx.Id; // Will be set after save? No, need save first or navigation prop
                
                // Save WalletTx first to get Id
                await _context.SaveChangesAsync();
                
                booking.TransactionId = walletTx.Id;
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();

                await _hubContext.Clients.All.SendAsync("UpdateCalendar", "Đặt sân thành công");

                return Ok(new { Message = "Thanh toán thành công", NewBalance = member.WalletBalance });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, ex.Message);
            }
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
        /// <summary>PHẦN 3: POST /api/bookings/cancel/{id} - Hủy sân (alias của DELETE).</summary>
        [HttpPost("cancel/{id}")]
        [Authorize]
        public Task<IActionResult> CancelBookingByPost(int id) => CancelBooking(id);

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
                member.TotalSpent -= booking.TotalPrice;

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
        [HttpPost("recurring")]
        [Authorize]
        public async Task<IActionResult> CreateRecurringBooking([FromBody] RecurringBookingRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized("Không tìm thấy thông tin thành viên");

            // VIP Check: Only Gold (2) or Diamond (3) can book recurring
            if ((int)member.Tier < 2) return Forbid("Chỉ thành viên Vàng trở lên mới được đặt lịch cố định");

            var court = await _context.Courts.FindAsync(request.CourtId);
            if (court == null) return BadRequest("Sân không hợp lệ");

            var bookingsToCreate = new List<Booking>();
            decimal totalCost = 0;
            var currentDate = request.StartDate.Date;
            var endDate = request.EndDate.Date;

            // Generate slots
            while (currentDate <= endDate)
            {
                // Check if current day of week is selected (0=Sunday, 1=Monday...)
                if (request.DaysOfWeek.Contains((int)currentDate.DayOfWeek))
                {
                    var start = currentDate.Add(request.StartTime.TimeOfDay);
                    var end = currentDate.Add(request.EndTime.TimeOfDay);

                    // Basic overlap check (should be optimized for batch)
                    bool isOverlapping = await _context.Bookings.AnyAsync(b =>
                        b.CourtId == request.CourtId &&
                        b.Status != BookingStatus.Cancelled &&
                        ((start >= b.StartTime && start < b.EndTime) ||
                         (end > b.StartTime && end <= b.EndTime)));

                    if (!isOverlapping)
                    {
                        var duration = (end - start).TotalHours;
                        var price = (decimal)duration * court.PricePerHour;
                        
                        bookingsToCreate.Add(new Booking
                        {
                            CourtId = request.CourtId,
                            MemberId = member.Id,
                            StartTime = start,
                            EndTime = end,
                            TotalPrice = price,
                            Status = BookingStatus.Confirmed
                        });
                        totalCost += price;
                    }
                }
                currentDate = currentDate.AddDays(1);
            }

            if (!bookingsToCreate.Any()) return BadRequest("Không tạo được lịch nào (có thể do trùng giờ hoặc không khớp ngày)");

            if (member.WalletBalance < totalCost) return BadRequest($"Số dư không đủ. Cần {totalCost}, có {member.WalletBalance}");

            using var transaction = _context.Database.BeginTransaction();
            try
            {
                // Create one transaction for total
                var walletTx = new WalletTransaction
                {
                    MemberId = member.Id,
                    Amount = -totalCost,
                    Type = TransactionType.Payment,
                    Status = TransactionStatus.Completed,
                    Description = $"Thanh toán lịch cố định ({bookingsToCreate.Count} buổi)",
                    CreatedDate = DateTime.Now
                };
                _context.WalletTransactions.Add(walletTx);
                member.WalletBalance -= totalCost;
                member.TotalSpent += totalCost;

                await _context.SaveChangesAsync();

                foreach (var b in bookingsToCreate)
                {
                    b.TransactionId = walletTx.Id;
                    _context.Bookings.Add(b);
                }
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();
                await _hubContext.Clients.All.SendAsync("UpdateCalendar", "Có lịch cố định mới");

                return Ok(new { count = bookingsToCreate.Count, totalCost });
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

    public class RecurringBookingRequest
    {
        public int CourtId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public DateTime StartTime { get; set; } // Only time part matters
        public DateTime EndTime { get; set; }   // Only time part matters
        public List<int> DaysOfWeek { get; set; } = new(); // 0=Sunday, 1=Monday...
    }
}
