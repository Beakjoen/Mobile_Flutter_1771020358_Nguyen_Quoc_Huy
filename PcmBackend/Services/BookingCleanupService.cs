using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Hubs;
using PcmBackend.Models;

namespace PcmBackend.Services
{
    public class BookingCleanupService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<BookingCleanupService> _logger;

        public BookingCleanupService(IServiceProvider serviceProvider, ILogger<BookingCleanupService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Booking Cleanup Service running.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using (var scope = _serviceProvider.CreateScope())
                    {
                        var context = scope.ServiceProvider.GetRequiredService<PcmDbContext>();
                        var hubContext = scope.ServiceProvider.GetRequiredService<IHubContext<PcmHub>>();

                        var timeout = DateTime.Now.AddMinutes(-5);
                        
                        // Find "Holding" bookings created more than 5 minutes ago
                        var expiredBookings = await context.Bookings
                            .Where(b => b.Status == BookingStatus.Holding && b.CreatedDate < timeout)
                            .ToListAsync(stoppingToken);

                        if (expiredBookings.Any())
                        {
                            foreach (var booking in expiredBookings)
                            {
                                booking.Status = BookingStatus.Cancelled;
                            }
                            await context.SaveChangesAsync(stoppingToken);

                            await hubContext.Clients.All.SendAsync("UpdateCalendar", $"Đã giải phóng {expiredBookings.Count} slot hết hạn giữ chỗ", stoppingToken);
                            _logger.LogInformation($"Released {expiredBookings.Count} expired holding bookings.");
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in Booking Cleanup Service");
                }

                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }
    }
}
