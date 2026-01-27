using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Services
{
    public class TournamentCleanupService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<TournamentCleanupService> _logger;

        public TournamentCleanupService(IServiceProvider serviceProvider, ILogger<TournamentCleanupService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Tournament Cleanup Service running.");

            using var timer = new PeriodicTimer(TimeSpan.FromMinutes(1)); // Check every minute

            while (await timer.WaitForNextTickAsync(stoppingToken))
            {
                try
                {
                    await CheckTournamentsAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred while checking tournaments.");
                }
            }
        }

        private async Task CheckTournamentsAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<PcmDbContext>();

            var now = DateTime.Now;

            // 1. Mark expired tournaments as Finished
            var expiredTournaments = await context.Tournaments
                .Where(t => t.EndDate <= now && t.Status != TournamentStatus.Finished)
                .ToListAsync();

            if (expiredTournaments.Any())
            {
                foreach (var t in expiredTournaments)
                {
                    t.Status = TournamentStatus.Finished;
                    _logger.LogInformation($"Tournament {t.Id} ({t.Name}) marked as Finished.");
                }
                await context.SaveChangesAsync();
            }

            // 2. Mark started tournaments as Ongoing (if they were Open)
            var startedTournaments = await context.Tournaments
                .Where(t => t.StartDate <= now && t.EndDate > now && t.Status == TournamentStatus.Open)
                .ToListAsync();

            if (startedTournaments.Any())
            {
                foreach (var t in startedTournaments)
                {
                    t.Status = TournamentStatus.Ongoing;
                    _logger.LogInformation($"Tournament {t.Id} ({t.Name}) marked as Ongoing.");
                }
                await context.SaveChangesAsync();
            }
        }
    }
}
