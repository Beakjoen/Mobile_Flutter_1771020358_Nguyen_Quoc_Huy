using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models
{
    /// <summary>Kèo thách đấu (Duel) — 1vs1 hoặc 2vs2 với phần thưởng nhỏ.</summary>
    [Table("358_Challenges")]
    public class Challenge
    {
        [Key]
        public int Id { get; set; }

        public int ChallengerId { get; set; }
        [ForeignKey("ChallengerId")]
        public Member? Challenger { get; set; }

        /// <summary>Đối thủ (null = mở cho bất kỳ ai chấp nhận).</summary>
        public int? OpponentId { get; set; }
        [ForeignKey("OpponentId")]
        public Member? Opponent { get; set; }

        /// <summary>Tiền đặt cọc mỗi bên (phần thưởng nhỏ). Người thắng nhận tổng 2 phần.</summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal StakeAmount { get; set; }

        public ChallengeStatus Status { get; set; } = ChallengeStatus.Pending;

        /// <summary>Người thắng (sau khi cập nhật kết quả).</summary>
        public int? WinnerId { get; set; }
        [ForeignKey("WinnerId")]
        public Member? Winner { get; set; }

        public string? Message { get; set; }
        public DateTime CreatedDate { get; set; } = DateTime.Now;
        public DateTime? AcceptedDate { get; set; }
        public DateTime? FinishedDate { get; set; }
    }
}
