using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TournamentsController : ControllerBase
    {
        private readonly PcmDbContext _context;

        public TournamentsController(PcmDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Tournament>>> GetTournaments()
        {
            return await _context.Tournaments.ToListAsync();
        }
        
        [HttpGet("{id}")]
        public async Task<ActionResult<Tournament>> GetTournament(int id)
        {
            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null) return NotFound();
            return tournament;
        }

        /// <summary>Lấy danh sách trận đấu của giải (kèm tên VĐV để hiển thị thật).</summary>
        [HttpGet("{id}/matches")]
        public async Task<ActionResult<IEnumerable<object>>> GetTournamentMatches(int id)
        {
            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null) return NotFound();

            var matches = await _context.Matches
                .Where(m => m.TournamentId == id)
                .OrderBy(m => m.Date).ThenBy(m => m.StartTime)
                .ToListAsync();

            var memberIds = matches
                .SelectMany(m => new[] { m.Team1_Player1Id, m.Team1_Player2Id, m.Team2_Player1Id, m.Team2_Player2Id })
                .Where(x => x.HasValue).Select(x => x!.Value).Distinct().ToList();
            var members = await _context.Members.Where(m => memberIds.Contains(m.Id)).ToDictionaryAsync(m => m.Id, m => m.FullName);

            var list = matches.Select(m => new
            {
                m.Id,
                m.TournamentId,
                m.RoundName,
                m.Date,
                StartTime = m.StartTime.ToString(@"hh\:mm"),
                Team1Name = m.Team1_Player1Id.HasValue ? members.GetValueOrDefault(m.Team1_Player1Id.Value, "?") : "TBD",
                Team2Name = m.Team2_Player1Id.HasValue ? members.GetValueOrDefault(m.Team2_Player1Id.Value, "?") : "TBD",
                m.Score1,
                m.Score2,
                m.Details,
                WinningSide = (int?)m.WinningSide,
                Status = (int)m.Status // 0=Scheduled, 1=InProgress, 2=Finished
            }).ToList();

            return Ok(list);
        }

        [HttpPost]
        [Authorize] // For demo, allow any logged in user to create. Real app: Admin only.
        public async Task<ActionResult<Tournament>> CreateTournament(Tournament tournament)
        {
            if (string.IsNullOrEmpty(tournament.Name)) return BadRequest("Tên giải đấu không được để trống");
            
            // Set defaults if missing
            if (tournament.StartDate == default) tournament.StartDate = DateTime.Now.AddDays(7);
            if (tournament.EndDate == default) tournament.EndDate = DateTime.Now.AddDays(14);
            
            _context.Tournaments.Add(tournament);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetTournament), new { id = tournament.Id }, tournament);
        }

        /// <summary>Danh sách người tham gia giải — dùng để hiển thị "N người đã đăng ký" và "Bạn đã tham gia".</summary>
        [HttpGet("{id}/participants")]
        [Authorize]
        public async Task<ActionResult<object>> GetTournamentParticipants(int id)
        {
            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null) return NotFound();

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var currentMember = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);

            var list = await _context.TournamentParticipants
                .Where(tp => tp.TournamentId == id)
                .OrderBy(tp => tp.Id)
                .Select(tp => new { tp.Id, tp.MemberId, tp.TeamName, MemberName = tp.Member != null ? tp.Member.FullName : "" })
                .ToListAsync();

            var currentUserJoined = currentMember != null && list.Any(p => p.MemberId == currentMember.Id);

            return Ok(new { participants = list, count = list.Count, currentUserJoined });
        }

        [HttpPost("{id}/join")]
        [Authorize]
        public async Task<IActionResult> JoinTournament(int id, [FromBody] JoinTournamentRequest? request)
        {
            if (request == null) return BadRequest("Thiếu thông tin đăng ký.");

            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null) return NotFound();

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized("Không tìm thấy thông tin thành viên.");

            if (member.WalletBalance < tournament.EntryFee)
                return BadRequest("Số dư ví không đủ. Vui lòng nạp thêm tiền.");

            var alreadyJoined = await _context.TournamentParticipants
                .AnyAsync(tp => tp.TournamentId == id && tp.MemberId == member.Id);
            if (alreadyJoined) return BadRequest("Bạn đã đăng ký giải này rồi.");

            using var transaction = _context.Database.BeginTransaction();
            try
            {
                var walletTx = new WalletTransaction
                {
                    MemberId = member.Id,
                    Amount = -tournament.EntryFee,
                    Type = TransactionType.Payment,
                    Status = TransactionStatus.Completed,
                    Description = $"Phí tham gia giải {tournament.Name}",
                    CreatedDate = DateTime.Now
                };
                _context.WalletTransactions.Add(walletTx);
                member.WalletBalance -= tournament.EntryFee;
                member.TotalSpent += tournament.EntryFee;

                var participant = new TournamentParticipant
                {
                    TournamentId = id,
                    MemberId = member.Id,
                    TeamName = request.TeamName ?? "",
                    PaymentStatus = true
                };
                _context.TournamentParticipants.Add(participant);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { participant, message = "Đăng ký thành công." });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, "Lỗi khi lưu: " + ex.Message);
            }
        }

        /// <summary>PHẦN 3: Auto-Scheduler chia bảng/cặp đấu. POST /api/tournaments/{id}/generate-schedule</summary>
        [HttpPost("{id}/generate-schedule")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GenerateSchedule(int id)
        {
            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null) return NotFound();

            var participants = await _context.TournamentParticipants
                .Where(tp => tp.TournamentId == id)
                .Include(tp => tp.Member)
                .ToListAsync();
            if (participants.Count < 2) return BadRequest("Cần ít nhất 2 người tham gia để tạo lịch");

            var rnd = new Random();
            var baseDate = tournament.StartDate.Date;
            int matchOrder = 0;

            if (tournament.Format == TournamentFormat.Knockout)
            {
                // Đơn giản: cặp đấu loại trực tiếp (Round 1)
                var shuffled = participants.OrderBy(_ => rnd.Next()).ToList();
                for (int i = 0; i < shuffled.Count - 1; i += 2)
                {
                    var m = new Match
                    {
                        TournamentId = id,
                        RoundName = "Vòng 1",
                        Date = baseDate,
                        StartTime = TimeSpan.FromHours(9 + (matchOrder % 4)),
                        Team1_Player1Id = shuffled[i].MemberId,
                        Team2_Player1Id = shuffled[i + 1].MemberId,
                        Status = MatchStatus.Scheduled,
                        IsRanked = true
                    };
                    _context.Matches.Add(m);
                    matchOrder++;
                }
            }
            else
            {
                // RoundRobin: mỗi cặp gặp nhau 1 lần
                for (int i = 0; i < participants.Count; i++)
                {
                    for (int j = i + 1; j < participants.Count; j++)
                    {
                        var m = new Match
                        {
                            TournamentId = id,
                            RoundName = "Vòng bảng",
                            Date = baseDate.AddDays(matchOrder / 4),
                            StartTime = TimeSpan.FromHours(9 + (matchOrder % 4)),
                            Team1_Player1Id = participants[i].MemberId,
                            Team2_Player1Id = participants[j].MemberId,
                            Status = MatchStatus.Scheduled,
                            IsRanked = true
                        };
                        _context.Matches.Add(m);
                        matchOrder++;
                    }
                }
            }

            tournament.Status = TournamentStatus.DrawCompleted;
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Đã tạo lịch thi đấu", MatchCount = matchOrder });
        }
    }

    public class JoinTournamentRequest
    {
        public string? TeamName { get; set; }
    }
}
