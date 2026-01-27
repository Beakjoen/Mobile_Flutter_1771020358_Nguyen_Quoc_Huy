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

        [HttpGet]
        public async Task<ActionResult<IEnumerable<dynamic>>> GetMembers([FromQuery] string? search)
        {
            var query = _context.Members
                .Include(m => m.User)
                .AsQueryable();

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(m => m.FullName.Contains(search) || (m.User != null && m.User.Email.Contains(search)));
            }

            var members = await query.ToListAsync();

            return Ok(members.Select(m => new {
                m.Id,
                m.FullName,
                m.RankLevel,
                m.WalletBalance,
                m.Tier,
                m.AvatarUrl,
                Email = m.User?.Email,
                PhoneNumber = m.User?.PhoneNumber
            }));
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
