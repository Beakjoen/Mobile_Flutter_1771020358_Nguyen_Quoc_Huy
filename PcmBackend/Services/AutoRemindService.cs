using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Hubs;
using PcmBackend.Models;

namespace PcmBackend.Services
{
    public class AutoRemindService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<AutoRemindService> _logger;

        public AutoRemindService(IServiceProvider serviceProvider, ILogger<AutoRemindService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Auto Remind Service running.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using (var scope = _serviceProvider.CreateScope())
                    {
                        var context = scope.ServiceProvider.GetRequiredService<PcmDbContext>();
                        var hubContext = scope.ServiceProvider.GetRequiredService<IHubContext<PcmHub>>();

                        var tomorrow = DateTime.Now.AddDays(1).Date;
                        var dayAfter = tomorrow.AddDays(1);

                        // PHẦN 4: Nhắc lịch đặt sân (bookings) ngày mai
                        var upcomingBookings = await context.Bookings
                            .Include(b => b.Member)
                            .Include(b => b.Court)
                            .Where(b => b.StartTime >= tomorrow && b.StartTime < dayAfter && b.Status == BookingStatus.Confirmed)
                            .ToListAsync(stoppingToken);

                        foreach (var booking in upcomingBookings)
                        {
                            if (booking.Member?.UserId != null)
                            {
                                var message = $"Nhắc lịch: Bạn có lịch đặt sân {booking.Court?.Name} vào ngày mai lúc {booking.StartTime:HH:mm}.";
                                await hubContext.Clients.User(booking.Member.UserId).SendAsync("ReceiveNotification", message, stoppingToken);
                                _logger.LogInformation($"Sent booking reminder to {booking.Member.FullName} for booking {booking.Id}");
                            }
                        }

                        // PHẦN 4: Nhắc lịch đấu (matches) trước 1 ngày
                        var upcomingMatches = await context.Matches
                            .Include(m => m.Tournament)
                            .Where(m => m.TournamentId != null && m.Date >= tomorrow && m.Date < dayAfter && m.Status == MatchStatus.Scheduled)
                            .ToListAsync(stoppingToken);

                        foreach (var match in upcomingMatches)
                        {
                            var memberIds = new[] { match.Team1_Player1Id, match.Team1_Player2Id, match.Team2_Player1Id, match.Team2_Player2Id }.Where(x => x.HasValue).Select(x => x!.Value).Distinct().ToList();
                            foreach (var mid in memberIds)
                            {
                                var member = await context.Members.FindAsync(mid);
                                if (member?.UserId != null)
                                {
                                    var message = $"Nhắc lịch đấu: Bạn có trận đấu {match.RoundName} vào ngày mai lúc {match.StartTime}.";
                                    await hubContext.Clients.User(member.UserId).SendAsync("ReceiveNotification", message, stoppingToken);
                                    _logger.LogInformation($"Sent match reminder to {member.FullName} for match {match.Id}");
                                }
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in Auto Remind Service");
                }

                // Run every hour to be safe, or just once a day. For demo, every 5 mins.
                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
            }
        }
    }
}
