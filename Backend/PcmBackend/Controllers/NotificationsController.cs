using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using PcmBackend.Hubs;

namespace PcmBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NotificationsController : ControllerBase
    {
        private readonly IHubContext<PcmHub> _hubContext;

        public NotificationsController(IHubContext<PcmHub> hubContext)
        {
            _hubContext = hubContext;
        }

        [HttpPost("broadcast")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Broadcast([FromBody] NotificationRequest request)
        {
            await _hubContext.Clients.All.SendAsync("ReceiveNotification", request.Message);
            return Ok("Sent broadcast");
        }

        [HttpPost("user/{userId}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> SendToUser(string userId, [FromBody] NotificationRequest request)
        {
            // Note: SignalR User ID mapping depends on IUserIdProvider. Default is ClaimTypes.NameIdentifier.
            await _hubContext.Clients.User(userId).SendAsync("ReceiveNotification", request.Message);
            return Ok($"Sent to user {userId}");
        }
    }

    public class NotificationRequest
    {
        public string Message { get; set; } = string.Empty;
    }
}
