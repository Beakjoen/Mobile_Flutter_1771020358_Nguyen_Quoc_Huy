using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CourtsController : ControllerBase
    {
        private readonly PcmDbContext _context;

        public CourtsController(PcmDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Court>>> GetCourts()
        {
            return await _context.Courts.Where(c => c.IsActive).ToListAsync();
        }
        
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<Court>> CreateCourt(Court court)
        {
            _context.Courts.Add(court);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetCourts), new { id = court.Id }, court);
        }
    }
}
