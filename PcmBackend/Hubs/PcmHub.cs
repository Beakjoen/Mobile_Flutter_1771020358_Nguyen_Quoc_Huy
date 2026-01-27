using Microsoft.AspNetCore.SignalR;

namespace PcmBackend.Hubs
{
    public class PcmHub : Hub
    {
        public async Task SendNotification(string user, string message)
        {
            await Clients.User(user).SendAsync("ReceiveNotification", message);
        }

        public async Task UpdateCalendar(string message)
        {
            await Clients.All.SendAsync("UpdateCalendar", message);
        }

        public async Task UpdateMatchScore(string matchId, string score)
        {
            await Clients.Group(matchId).SendAsync("UpdateMatchScore", matchId, score);
        }

        public async Task JoinMatchGroup(string matchId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, matchId);
        }

        public async Task LeaveMatchGroup(string matchId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, matchId);
        }
    }
}
