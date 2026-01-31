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
    /// <summary>API Thách đấu (Duel) — tạo kèo, chấp nhận, cập nhật kết quả, hủy.</summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ChallengesController : ControllerBase
    {
        private readonly PcmDbContext _context;
        private readonly IHubContext<PcmHub> _hubContext;

        public ChallengesController(PcmDbContext context, IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        private async Task<Member?> GetCurrentMemberAsync()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        }

        /// <summary>POST /api/challenges — Tạo kèo thách đấu, trừ tiền đặt cọc của người thách.</summary>
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateChallengeRequest request)
        {
            var challenger = await GetCurrentMemberAsync();
            if (challenger == null) return Unauthorized("Không tìm thấy thông tin thành viên");

            if (request.StakeAmount <= 0)
                return BadRequest("Số tiền đặt cọc phải lớn hơn 0");

            if (challenger.WalletBalance < request.StakeAmount)
                return BadRequest("Số dư ví không đủ để đặt cọc");

            var challenge = new Challenge
            {
                ChallengerId = challenger.Id,
                OpponentId = request.OpponentId,
                StakeAmount = request.StakeAmount,
                Status = ChallengeStatus.Pending,
                Message = request.Message,
                CreatedDate = DateTime.Now
            };

            challenger.WalletBalance -= request.StakeAmount;
            _context.Challenges.Add(challenge);

            var stakeTx = new WalletTransaction
            {
                MemberId = challenger.Id,
                Amount = -request.StakeAmount,
                Type = TransactionType.Payment,
                Status = TransactionStatus.Completed,
                RelatedId = "Challenge",
                Description = "Đặt cọc thách đấu (chờ đối thủ)",
                CreatedDate = DateTime.Now
            };
            _context.WalletTransactions.Add(stakeTx);

            await _context.SaveChangesAsync();

            if (request.OpponentId.HasValue && request.OpponentId.Value != challenger.Id)
            {
                var opponent = await _context.Members.FindAsync(request.OpponentId.Value);
                if (opponent?.UserId != null)
                    await _hubContext.Clients.User(opponent.UserId).SendAsync("ReceiveNotification", $"{challenger.FullName} thách đấu bạn với kèo {request.StakeAmount:N0} đ.");
            }

            return Ok(await ToChallengeDto(challenge));
        }

        /// <summary>GET /api/challenges — Danh sách kèo (filter: mine, open, finished).</summary>
        [HttpGet]
        public async Task<ActionResult<IEnumerable<object>>> GetList([FromQuery] string? filter = null)
        {
            var member = await GetCurrentMemberAsync();
            if (member == null) return Unauthorized();

            var query = _context.Challenges
                .Include(c => c.Challenger)
                .Include(c => c.Opponent)
                .Include(c => c.Winner)
                .AsQueryable();

            switch (filter?.ToLowerInvariant())
            {
                case "mine":
                    query = query.Where(c => c.ChallengerId == member.Id || c.OpponentId == member.Id);
                    break;
                case "open":
                    query = query.Where(c => c.Status == ChallengeStatus.Pending);
                    break;
                case "finished":
                    query = query.Where(c => c.Status == ChallengeStatus.Finished || c.Status == ChallengeStatus.Cancelled);
                    break;
            }

            var list = await query.OrderByDescending(c => c.CreatedDate).ToListAsync();
            var dtos = new List<object>();
            foreach (var c in list)
                dtos.Add(await ToChallengeDto(c));
            return Ok(dtos);
        }

        /// <summary>GET /api/challenges/{id} — Chi tiết một kèo.</summary>
        [HttpGet("{id}")]
        public async Task<ActionResult<object>> GetById(int id)
        {
            var challenge = await _context.Challenges
                .Include(c => c.Challenger)
                .Include(c => c.Opponent)
                .Include(c => c.Winner)
                .FirstOrDefaultAsync(c => c.Id == id);
            if (challenge == null) return NotFound();
            return Ok(await ToChallengeDto(challenge));
        }

        /// <summary>POST /api/challenges/{id}/accept — Chấp nhận kèo, trừ tiền đặt cọc đối thủ.</summary>
        [HttpPost("{id}/accept")]
        public async Task<IActionResult> Accept(int id)
        {
            var member = await GetCurrentMemberAsync();
            if (member == null) return Unauthorized();

            var challenge = await _context.Challenges
                .Include(c => c.Challenger)
                .Include(c => c.Opponent)
                .FirstOrDefaultAsync(c => c.Id == id);
            if (challenge == null) return NotFound();
            if (challenge.Status != ChallengeStatus.Pending)
                return BadRequest("Kèo không còn ở trạng thái chờ chấp nhận");

            if (challenge.ChallengerId == member.Id)
                return BadRequest("Bạn là người thách đấu, không thể tự chấp nhận");

            if (challenge.OpponentId.HasValue && challenge.OpponentId != member.Id)
                return BadRequest("Kèo này đã được mời cho thành viên khác");

            if (member.WalletBalance < challenge.StakeAmount)
                return BadRequest("Số dư ví không đủ để tham gia");

            challenge.OpponentId = member.Id;
            challenge.Status = ChallengeStatus.Accepted;
            challenge.AcceptedDate = DateTime.Now;
            member.WalletBalance -= challenge.StakeAmount;

            var stakeTx = new WalletTransaction
            {
                MemberId = member.Id,
                Amount = -challenge.StakeAmount,
                Type = TransactionType.Payment,
                Status = TransactionStatus.Completed,
                RelatedId = "Challenge",
                Description = $"Đặt cọc chấp nhận thách đấu #{challenge.Id}",
                CreatedDate = DateTime.Now
            };
            _context.WalletTransactions.Add(stakeTx);

            await _context.SaveChangesAsync();

            var challenger = await _context.Members.FindAsync(challenge.ChallengerId);
            if (challenger?.UserId != null)
                await _hubContext.Clients.User(challenger.UserId).SendAsync("ReceiveNotification", $"{member.FullName} đã chấp nhận thách đấu #{challenge.Id}.");

            return Ok(await ToChallengeDto(challenge));
        }

        /// <summary>POST /api/challenges/{id}/result — Cập nhật kết quả (chỉ challenger hoặc opponent), công tiền thưởng cho người thắng.</summary>
        [HttpPost("{id}/result")]
        public async Task<IActionResult> SetResult(int id, [FromBody] SetChallengeResultRequest request)
        {
            var member = await GetCurrentMemberAsync();
            if (member == null) return Unauthorized();

            var challenge = await _context.Challenges
                .Include(c => c.Challenger)
                .Include(c => c.Opponent)
                .FirstOrDefaultAsync(c => c.Id == id);
            if (challenge == null) return NotFound();
            if (challenge.Status != ChallengeStatus.Accepted)
                return BadRequest("Chỉ có thể cập nhật kết quả khi kèo đã được chấp nhận");

            if (challenge.ChallengerId != member.Id && challenge.OpponentId != member.Id)
                return BadRequest("Chỉ người tham gia kèo mới được cập nhật kết quả");

            int winnerId = request.WinnerId;
            if (winnerId != challenge.ChallengerId && winnerId != (challenge.OpponentId ?? 0))
                return BadRequest("WinnerId phải là Challenger hoặc Opponent");

            challenge.WinnerId = winnerId;
            challenge.Status = ChallengeStatus.Finished;
            challenge.FinishedDate = DateTime.Now;

            var winner = await _context.Members.FindAsync(winnerId);
            if (winner != null)
            {
                var prize = challenge.StakeAmount * 2;
                winner.WalletBalance += prize;
                var rewardTx = new WalletTransaction
                {
                    MemberId = winner.Id,
                    Amount = prize,
                    Type = TransactionType.Reward,
                    Status = TransactionStatus.Completed,
                    RelatedId = "Challenge",
                    Description = $"Thắng thách đấu #{challenge.Id}",
                    CreatedDate = DateTime.Now
                };
                _context.WalletTransactions.Add(rewardTx);
            }

            await _context.SaveChangesAsync();

            if (challenge.Challenger?.UserId != null)
                await _hubContext.Clients.User(challenge.Challenger.UserId).SendAsync("ReceiveNotification", $"Kết quả thách đấu #{challenge.Id}: {(winnerId == challenge.ChallengerId ? "Bạn thắng" : "Bạn thua")}.");
            if (challenge.Opponent?.UserId != null && challenge.Opponent.UserId != challenge.Challenger?.UserId)
                await _hubContext.Clients.User(challenge.Opponent.UserId).SendAsync("ReceiveNotification", $"Kết quả thách đấu #{challenge.Id}: {(winnerId == challenge.OpponentId ? "Bạn thắng" : "Bạn thua")}.");

            return Ok(await ToChallengeDto(challenge));
        }

        /// <summary>POST /api/challenges/{id}/cancel — Hủy kèo, hoàn tiền đặt cọc (chỉ khi Pending hoặc Accepted chưa đấu).</summary>
        [HttpPost("{id}/cancel")]
        public async Task<IActionResult> Cancel(int id)
        {
            var member = await GetCurrentMemberAsync();
            if (member == null) return Unauthorized();

            var challenge = await _context.Challenges
                .Include(c => c.Challenger)
                .Include(c => c.Opponent)
                .FirstOrDefaultAsync(c => c.Id == id);
            if (challenge == null) return NotFound();
            if (challenge.Status == ChallengeStatus.Finished)
                return BadRequest("Kèo đã kết thúc, không thể hủy");
            if (challenge.Status == ChallengeStatus.Cancelled)
                return BadRequest("Kèo đã bị hủy");

            bool isChallenger = challenge.ChallengerId == member.Id;
            bool isOpponent = challenge.OpponentId == member.Id;
            if (!isChallenger && !isOpponent)
                return BadRequest("Chỉ người tham gia mới được hủy kèo");

            challenge.Status = ChallengeStatus.Cancelled;

            var challenger = await _context.Members.FindAsync(challenge.ChallengerId);
            if (challenger != null)
            {
                challenger.WalletBalance += challenge.StakeAmount;
                _context.WalletTransactions.Add(new WalletTransaction
                {
                    MemberId = challenger.Id,
                    Amount = challenge.StakeAmount,
                    Type = TransactionType.Refund,
                    Status = TransactionStatus.Completed,
                    RelatedId = "Challenge",
                    Description = $"Hoàn tiền hủy thách đấu #{challenge.Id}",
                    CreatedDate = DateTime.Now
                });
            }

            if (challenge.OpponentId.HasValue)
            {
                var opponent = await _context.Members.FindAsync(challenge.OpponentId.Value);
                if (opponent != null)
                {
                    opponent.WalletBalance += challenge.StakeAmount;
                    _context.WalletTransactions.Add(new WalletTransaction
                    {
                        MemberId = opponent.Id,
                        Amount = challenge.StakeAmount,
                        Type = TransactionType.Refund,
                        Status = TransactionStatus.Completed,
                        RelatedId = "Challenge",
                        Description = $"Hoàn tiền hủy thách đấu #{challenge.Id}",
                        CreatedDate = DateTime.Now
                    });
                }
            }

            await _context.SaveChangesAsync();

            return Ok(await ToChallengeDto(challenge));
        }

        private async Task<object> ToChallengeDto(Challenge c)
        {
            await _context.Entry(c).Reference(x => x.Challenger).LoadAsync();
            await _context.Entry(c).Reference(x => x.Opponent).LoadAsync();
            await _context.Entry(c).Reference(x => x.Winner).LoadAsync();
            return new
            {
                c.Id,
                c.ChallengerId,
                ChallengerName = c.Challenger?.FullName,
                c.OpponentId,
                OpponentName = c.Opponent?.FullName,
                c.StakeAmount,
                Status = c.Status.ToString(),
                c.WinnerId,
                WinnerName = c.Winner?.FullName,
                c.Message,
                c.CreatedDate,
                c.AcceptedDate,
                c.FinishedDate
            };
        }
    }

    public class CreateChallengeRequest
    {
        public decimal StakeAmount { get; set; }
        public int? OpponentId { get; set; }
        public string? Message { get; set; }
    }

    public class SetChallengeResultRequest
    {
        public int WinnerId { get; set; }
    }
}
