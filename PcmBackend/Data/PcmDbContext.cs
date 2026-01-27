using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Models;

namespace PcmBackend.Data
{
    public class PcmDbContext : IdentityDbContext
    {
        public PcmDbContext(DbContextOptions<PcmDbContext> options) : base(options)
        {
        }

        public DbSet<Member> Members { get; set; }
        public DbSet<WalletTransaction> WalletTransactions { get; set; }
        public DbSet<Court> Courts { get; set; }
        public DbSet<Booking> Bookings { get; set; }
        public DbSet<Tournament> Tournaments { get; set; }
        public DbSet<TournamentParticipant> TournamentParticipants { get; set; }
        public DbSet<Match> Matches { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<News> News { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Configure relationships if needed
            builder.Entity<Member>()
                .HasOne(m => m.User)
                .WithOne()
                .HasForeignKey<Member>(m => m.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<Booking>()
                .HasOne(b => b.Court)
                .WithMany()
                .HasForeignKey(b => b.CourtId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Entity<Booking>()
                .HasOne(b => b.Member)
                .WithMany()
                .HasForeignKey(b => b.MemberId)
                .OnDelete(DeleteBehavior.Restrict);

            // Add more configurations as needed
        }
    }
}
