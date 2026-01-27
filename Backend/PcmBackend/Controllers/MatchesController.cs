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
    /// <summary>PHẦN 3: POST /api/matches/{id}/result - Cập nhật kết quả, tính lại Rank DUPR, cập nhật nhánh đấu (Knockout).</summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class MatchesController : ControllerBase
    {
        private readonly PcmDbContext _context;
        private readonly IHubContext<PcmHub> _hubContext;

        public MatchesController(PcmDbContext context, IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Match>>> GetMatches([FromQuery] int? tournamentId)
        {
            var query = _context.Matches.AsQueryable();
            if (tournamentId.HasValue)
                query = query.Where(m => m.TournamentId == tournamentId);
            return await query.OrderBy(m => m.Date).ThenBy(m => m.StartTime).ToListAsync();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Match>> GetMatch(int id)
        {
            var m = await _context.Matches.FindAsync(id);
            if (m == null) return NotFound();
            return m;
        }

        [HttpPost("{id}/result")]
        [Authorize(Roles = "Admin,Referee")]
        public async Task<IActionResult> UpdateResult(int id, [FromBody] MatchResultRequest request)
        {
            var match = await _context.Matches.FindAsync(id);
            if (match == null) return NotFound();

            match.Score1 = request.Score1;
            match.Score2 = request.Score2;
            match.Details = request.Details;
            match.WinningSide = request.WinningSide;
            match.Status = MatchStatus.Finished;

            if (match.IsRanked && (match.Team1_Player1Id.HasValue || match.Team2_Player1Id.HasValue))
            {
                const double delta = 0.05;
                int? winnerId = request.WinningSide == WinningSide.Team1 ? match.Team1_Player1Id : match.Team2_Player1Id;
                int? loserId = request.WinningSide == WinningSide.Team1 ? match.Team2_Player1Id : match.Team1_Player1Id;
                if (winnerId.HasValue)
                {
                    var w = await _context.Members.FindAsync(winnerId);
                    if (w != null) w.RankLevel = Math.Max(1.0, Math.Min(6.0, w.RankLevel + delta));
                }
                if (loserId.HasValue)
                {
                    var l = await _context.Members.FindAsync(loserId);
                    if (l != null) l.RankLevel = Math.Max(1.0, Math.Min(6.0, l.RankLevel - delta));
                }
            }

            await _context.SaveChangesAsync();

            // PHẦN 4: Mỗi trận đấu là 1 Group SignalR (PcmHub.JoinMatchGroup(matchId)). Chỉ broadcast cho user đang xem trận đó.
            await _hubContext.Clients.Group(id.ToString()).SendAsync("UpdateMatchScore", id.ToString(), $"{match.Score1}-{match.Score2}");

            return Ok(match);
        }
    }

    public class MatchResultRequest
    {
        public int Score1 { get; set; }
        public int Score2 { get; set; }
        public string? Details { get; set; }
        public WinningSide WinningSide { get; set; }
    }
}
