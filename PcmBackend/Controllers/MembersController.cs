using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class MembersController : ControllerBase
    {
        private readonly PcmDbContext _context;

        public MembersController(PcmDbContext context)
        {
            _context = context;
        }

        /// <summary>Bảng xếp hạng theo tổng nạp (TotalDeposit). Dùng cho màn chính.</summary>
        [HttpGet("leaderboard")]
        public async Task<ActionResult<object>> GetLeaderboard([FromQuery] int top = 10)
        {
            var list = await _context.Members
                .OrderByDescending(m => m.TotalDeposit)
                .Take(Math.Clamp(top, 1, 50))
                .Select(m => new { m.Id, m.FullName, m.TotalDeposit, m.Tier })
                .ToListAsync();
            return Ok(list);
        }

        /// <summary>PHẦN 3: GET /api/members - Danh sách members (Search, Filter, Pagination).</summary>
        [HttpGet]
        public async Task<ActionResult<object>> GetMembers(
            [FromQuery] string? search,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var query = _context.Members
                .Include(m => m.User)
                .AsQueryable();

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(m => m.FullName.Contains(search) || (m.User != null && m.User.Email.Contains(search)));
            }

            var total = await query.CountAsync();
            var members = await query
                .OrderBy(m => m.FullName)
                .Skip((page - 1) * pageSize)
                .Take(Math.Min(pageSize, 100))
                .ToListAsync();

            return Ok(new {
                Total = total,
                Page = page,
                PageSize = pageSize,
                Items = members.Select(m => new {
                m.Id,
                m.FullName,
                m.RankLevel,
                m.WalletBalance,
                m.Tier,
                m.AvatarUrl,
                Email = m.User?.Email,
                PhoneNumber = m.User?.PhoneNumber
            }).ToList()
            });
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Member>> GetMember(int id)
        {
            var member = await _context.Members.FindAsync(id);

            if (member == null)
            {
                return NotFound();
            }

            return member;
        }
        
        [HttpGet("{id}/profile")]
        public async Task<ActionResult<object>> GetMemberProfile(int id)
        {
             var member = await _context.Members.FindAsync(id);

            if (member == null)
            {
                return NotFound();
            }
            
            // In a real app, fetch history matches, ranks, etc.
            return Ok(new {
                Member = member,
                Matches = new List<object>(), // Placeholder
                RankHistory = new List<object>() // Placeholder
            });
        }
    }
}
