using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models
{
    [Table("358_Notifications")]
    public class Notification
    {
        [Key]
        public int Id { get; set; }

        public int ReceiverId { get; set; }
        [ForeignKey("ReceiverId")]
        public Member? Receiver { get; set; }

        public string Message { get; set; } = string.Empty;
        public NotificationType Type { get; set; }
        public string? LinkUrl { get; set; }
        public bool IsRead { get; set; }
        public DateTime CreatedDate { get; set; } = DateTime.Now;
    }

    [Table("358_News")]
    public class News
    {
        [Key]
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public bool IsPinned { get; set; }
        public DateTime CreatedDate { get; set; } = DateTime.Now;
        public string? ImageUrl { get; set; }
    }
}
