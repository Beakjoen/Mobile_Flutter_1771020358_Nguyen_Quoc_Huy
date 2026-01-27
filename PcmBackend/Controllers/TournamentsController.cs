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

        [HttpPost("{id}/join")]
        [Authorize]
        public async Task<IActionResult> JoinTournament(int id, [FromBody] JoinTournamentRequest request)
        {
            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null) return NotFound();

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized();

            if (member.WalletBalance < tournament.EntryFee) return BadRequest("Insufficient balance");

            // Check if already joined
            bool joined = await _context.TournamentParticipants
                .AnyAsync(tp => tp.TournamentId == id && tp.MemberId == member.Id);
            if (joined) return BadRequest("Already joined");

             using var transaction = _context.Database.BeginTransaction();
            try
            {
                // Deduct fee
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

                var participant = new TournamentParticipant
                {
                    TournamentId = id,
                    MemberId = member.Id,
                    TeamName = request.TeamName,
                    PaymentStatus = true
                };

                _context.TournamentParticipants.Add(participant);
                await _context.SaveChangesAsync();
                
                await transaction.CommitAsync();

                return Ok(participant);
            }
             catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, ex.Message);
            }
        }
    }

    public class JoinTournamentRequest
    {
        public string? TeamName { get; set; }
    }
}
