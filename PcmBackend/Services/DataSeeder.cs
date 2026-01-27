using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Services
{
    public static class DataSeeder
    {
        public static async Task SeedData(IServiceProvider serviceProvider)
        {
            var context = serviceProvider.GetRequiredService<PcmDbContext>();
            var userManager = serviceProvider.GetRequiredService<UserManager<IdentityUser>>();
            var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();

            context.Database.EnsureCreated();

            // 1. Roles
            string[] roles = { "Admin", "Treasurer", "Referee", "Member" };
            foreach (var role in roles)
            {
                if (!await roleManager.RoleExistsAsync(role))
                {
                    await roleManager.CreateAsync(new IdentityRole(role));
                }
            }

            // 2. System Users (Admin, Treasurer, Referee)
            var adminUser = await CreateUser(userManager, "admin", "Admin@123", "Admin");
            if (adminUser != null && !context.Members.Any(m => m.UserId == adminUser.Id))
            {
                context.Members.Add(new Member
                {
                    UserId = adminUser.Id,
                    FullName = "System Admin",
                    JoinDate = DateTime.Now,
                    RankLevel = 5.0,
                    WalletBalance = 0,
                    Tier = MemberTier.Diamond,
                    IsActive = true
                });
                await context.SaveChangesAsync();
            }

            await CreateUser(userManager, "treasurer", "Treasurer@123", "Treasurer");
            await CreateUser(userManager, "referee", "Referee@123", "Referee");

            // 3. Members (20 members)
            if (!context.Members.Any(m => m.FullName.StartsWith("Member")))
            {
                var rand = new Random();
                for (int i = 1; i <= 20; i++)
                {
                    var username = $"member{i}";
                    var user = await CreateUser(userManager, username, "Member@123", "Member");
                    
                    if (user != null)
                    {
                        // Check if member exists to avoid duplicate logic if partial fail
                        if (context.Members.Any(m => m.UserId == user.Id)) continue;

                        var rank = 3.0 + (i * 0.1); // 3.1 to 5.0
                        var member = new Member
                        {
                            UserId = user.Id,
                            FullName = $"Member {i}",
                            JoinDate = DateTime.Now.AddMonths(-i),
                            RankLevel = rank > 5.0 ? 5.0 : rank,
                            WalletBalance = rand.Next(2000000, 10000000),
                            Tier = i % 4 == 0 ? MemberTier.Diamond : (i % 3 == 0 ? MemberTier.Gold : (i % 2 == 0 ? MemberTier.Silver : MemberTier.Standard)),
                            IsActive = true,
                            TotalSpent = 0
                        };
                        context.Members.Add(member);
                        
                        // Seed Transactions for History
                        // 1. Initial Deposit
                        context.WalletTransactions.Add(new WalletTransaction
                        {
                            MemberId = member.Id,
                            Member = member, // Ensure link
                            Amount = member.WalletBalance,
                            Type = TransactionType.Deposit,
                            Status = TransactionStatus.Completed,
                            Description = "Nạp tiền lần đầu",
                            CreatedDate = DateTime.Now.AddMonths(-i)
                        });

                        // 2. Random spending
                        if (i % 2 == 0)
                        {
                            var spent = rand.Next(100000, 500000);
                            member.WalletBalance -= spent;
                            context.WalletTransactions.Add(new WalletTransaction
                            {
                                MemberId = member.Id,
                                Member = member,
                                Amount = -spent,
                                Type = TransactionType.Payment,
                                Status = TransactionStatus.Completed,
                                Description = "Thanh toán đặt sân",
                                CreatedDate = DateTime.Now.AddDays(-rand.Next(1, 30))
                            });
                        }
                    }
                }
                await context.SaveChangesAsync();
            }

            // 4. Courts
            if (!context.Courts.Any())
            {
                context.Courts.AddRange(
                    new Court { Name = "Sân 1", PricePerHour = 100000, Description = "Sân tiêu chuẩn" },
                    new Court { Name = "Sân 2", PricePerHour = 100000, Description = "Sân tiêu chuẩn" },
                    new Court { Name = "Sân 3", PricePerHour = 120000, Description = "Sân VIP" },
                    new Court { Name = "Sân 4", PricePerHour = 120000, Description = "Sân VIP" }
                );
                await context.SaveChangesAsync();
            }

            // 5. Tournaments
            if (!context.Tournaments.Any())
            {
                context.Tournaments.AddRange(
                    new Tournament
                    {
                        Name = "Summer Open 2026",
                        StartDate = DateTime.Now.AddMonths(-1),
                        EndDate = DateTime.Now.AddMonths(-1).AddDays(5),
                        Format = TournamentFormat.Knockout,
                        EntryFee = 200000,
                        PrizePool = 5000000,
                        Status = TournamentStatus.Finished
                    },
                    new Tournament
                    {
                        Name = "Winter Cup",
                        StartDate = DateTime.Now.AddMonths(1),
                        EndDate = DateTime.Now.AddMonths(1).AddDays(5),
                        Format = TournamentFormat.RoundRobin,
                        EntryFee = 300000,
                        PrizePool = 10000000,
                        Status = TournamentStatus.Open
                    }
                );
                await context.SaveChangesAsync();
            }

            if (!context.Tournaments.Any(t => t.Name == "Autumn League"))
            {
                context.Tournaments.Add(new Tournament
                {
                    Name = "Autumn League",
                    StartDate = DateTime.Now.AddDays(-3),
                    EndDate = DateTime.Now.AddDays(7),
                    Format = TournamentFormat.RoundRobin,
                    EntryFee = 150000,
                    PrizePool = 3000000,
                    Status = TournamentStatus.Ongoing
                });
                await context.SaveChangesAsync();
            }

            // 6. Matches cho giải đã kết thúc (Summer Open) và đang diễn ra (Autumn League) - dữ liệu thật
            var summer = await context.Tournaments.FirstOrDefaultAsync(t => t.Name == "Summer Open 2026");
            if (summer != null && !context.Matches.Any(m => m.TournamentId == summer.Id))
            {
                var members = await context.Members.Where(m => m.FullName.StartsWith("Member")).Take(4).Select(m => m.Id).ToListAsync();
                if (members.Count >= 4)
                {
                    var d = summer.EndDate.AddDays(-2).Date;
                    context.Matches.AddRange(
                        new Match { TournamentId = summer.Id, RoundName = "Vòng 1", Date = d, StartTime = TimeSpan.FromHours(9), Team1_Player1Id = members[0], Team2_Player1Id = members[1], Score1 = 2, Score2 = 1, WinningSide = WinningSide.Team1, Status = MatchStatus.Finished, IsRanked = true },
                        new Match { TournamentId = summer.Id, RoundName = "Vòng 1", Date = d, StartTime = TimeSpan.FromHours(10), Team1_Player1Id = members[2], Team2_Player1Id = members[3], Score1 = 1, Score2 = 2, WinningSide = WinningSide.Team2, Status = MatchStatus.Finished, IsRanked = true },
                        new Match { TournamentId = summer.Id, RoundName = "Bán kết", Date = d.AddDays(1), StartTime = TimeSpan.FromHours(9), Team1_Player1Id = members[0], Team2_Player1Id = members[3], Score1 = 2, Score2 = 0, WinningSide = WinningSide.Team1, Status = MatchStatus.Finished, IsRanked = true }
                    );
                    await context.SaveChangesAsync();
                }
            }

            var autumn = await context.Tournaments.FirstOrDefaultAsync(t => t.Name == "Autumn League");
            if (autumn != null && !context.Matches.Any(m => m.TournamentId == autumn.Id))
            {
                var members = await context.Members.Where(m => m.FullName.StartsWith("Member")).Skip(4).Take(4).Select(m => m.Id).ToListAsync();
                if (members.Count >= 2)
                {
                    var d = DateTime.Now.Date.AddDays(1);
                    context.Matches.AddRange(
                        new Match { TournamentId = autumn.Id, RoundName = "Vòng bảng", Date = d, StartTime = TimeSpan.FromHours(14), Team1_Player1Id = members[0], Team2_Player1Id = members[1], Status = MatchStatus.Scheduled, IsRanked = true },
                        new Match { TournamentId = autumn.Id, RoundName = "Vòng bảng", Date = d, StartTime = TimeSpan.FromHours(15), Team1_Player1Id = members.Count > 2 ? members[2] : members[0], Team2_Player1Id = members.Count > 3 ? members[3] : members[1], Status = MatchStatus.Scheduled, IsRanked = true }
                    );
                    await context.SaveChangesAsync();
                }
            }

            // Tính TotalDeposit và Tier từ lịch sử nạp (member1 và mọi member có giao dịch nạp Completed)
            var depositSums = await context.WalletTransactions
                .Where(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Completed)
                .GroupBy(t => t.MemberId)
                .Select(g => new { MemberId = g.Key, Total = g.Sum(t => t.Amount) })
                .ToListAsync();
            foreach (var d in depositSums)
            {
                var member = await context.Members.FindAsync(d.MemberId);
                if (member != null)
                {
                    member.TotalDeposit = d.Total;
                    MemberTierHelper.UpdateTier(member);
                }
            }
            if (depositSums.Count > 0)
                await context.SaveChangesAsync();
        }

        private static async Task<IdentityUser?> CreateUser(UserManager<IdentityUser> userManager, string username, string password, string role)
        {
            var user = await userManager.FindByNameAsync(username);
            if (user == null)
            {
                user = new IdentityUser { UserName = username, Email = $"{username}@example.com" };
                var result = await userManager.CreateAsync(user, password);
                if (!result.Succeeded) return null;
            }

            if (!await userManager.IsInRoleAsync(user, role))
            {
                await userManager.AddToRoleAsync(user, role);
            }

            return user;
        }
    }
}
