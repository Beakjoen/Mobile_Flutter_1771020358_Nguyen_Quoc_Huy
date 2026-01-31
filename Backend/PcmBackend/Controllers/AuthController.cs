using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly UserManager<IdentityUser> _userManager;
        private readonly SignInManager<IdentityUser> _signInManager;
        private readonly IConfiguration _configuration;
        private readonly PcmDbContext _context;

        public AuthController(
            UserManager<IdentityUser> userManager,
            SignInManager<IdentityUser> signInManager,
            IConfiguration configuration,
            PcmDbContext context)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _configuration = configuration;
            _context = context;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginModel model)
        {
            Console.WriteLine($"Login attempt for: {model.Username}");
            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null)
            {
                Console.WriteLine($"User not found: {model.Username}");
                return Unauthorized();
            }

            if (await _userManager.CheckPasswordAsync(user, model.Password))
            {
                Console.WriteLine($"Password correct for: {model.Username}");
                var userRoles = await _userManager.GetRolesAsync(user);
                // ... rest of the code


                var authClaims = new List<Claim>
                {
                    new Claim(ClaimTypes.Name, user.UserName),
                    new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                    new Claim(ClaimTypes.NameIdentifier, user.Id)
                };

                foreach (var role in userRoles)
                {
                    authClaims.Add(new Claim(ClaimTypes.Role, role));
                }

                var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["JWT:Secret"]));

                var token = new JwtSecurityToken(
                    issuer: _configuration["JWT:ValidIssuer"],
                    audience: _configuration["JWT:ValidAudience"],
                    expires: DateTime.Now.AddHours(3),
                    claims: authClaims,
                    signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
                );

                var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == user.Id);
                if (member == null)
                    return BadRequest("Tài khoản chưa được liên kết với hồ sơ thành viên. Liên hệ quản trị viên.");

                await SyncMemberTotalDepositAndTier(member);

                return Ok(new
                {
                    token = new JwtSecurityTokenHandler().WriteToken(token),
                    expiration = token.ValidTo,
                    member = new {
                        member.Id,
                        member.FullName,
                        member.RankLevel,
                        member.WalletBalance,
                        member.Tier,
                        member.TotalDeposit,
                        member.AvatarUrl,
                        Email = user.Email,
                        PhoneNumber = user.PhoneNumber,
                        Roles = userRoles
                    }
                });
            }
            return Unauthorized();
        }

        [HttpGet("me")]
        [Authorize]
        public async Task<IActionResult> GetMe()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return NotFound();

            await SyncMemberTotalDepositAndTier(member);

            var user = await _userManager.FindByIdAsync(userId!);
            var roles = await _userManager.GetRolesAsync(user!);

            return Ok(new
            {
                member.Id,
                member.FullName,
                member.RankLevel,
                member.WalletBalance,
                member.Tier,
                member.TotalDeposit,
                member.AvatarUrl,
                Email = user?.Email,
                PhoneNumber = user?.PhoneNumber,
                Roles = roles
            });
        }

        /// <summary>Đồng bộ TotalDeposit và Tier từ lịch sử nạp đã duyệt — đảm bảo hạng và thanh tiến trình luôn đúng.</summary>
        private async Task SyncMemberTotalDepositAndTier(Member member)
        {
            var totalDeposit = await _context.WalletTransactions
                .Where(t => t.MemberId == member.Id && t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Completed)
                .SumAsync(t => t.Amount);
            member.TotalDeposit = totalDeposit;
            MemberTierHelper.UpdateTier(member);
            await _context.SaveChangesAsync();
        }
    }

    public class LoginModel
    {
        public string Username { get; set; }
        public string Password { get; set; }
    }
}
