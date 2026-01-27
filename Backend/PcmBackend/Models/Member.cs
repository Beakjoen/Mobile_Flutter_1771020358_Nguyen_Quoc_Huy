using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Identity;

namespace PcmBackend.Models
{
    [Table("358_Members")]
    public class Member
    {
        [Key]
        public int Id { get; set; }

        public string FullName { get; set; } = string.Empty;
        public DateTime JoinDate { get; set; } = DateTime.Now;
        public double RankLevel { get; set; } // DUPR
        public bool IsActive { get; set; } = true;

        public string? UserId { get; set; }
        [ForeignKey("UserId")]
        public IdentityUser? User { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal WalletBalance { get; set; } = 0;

        public MemberTier Tier { get; set; } = MemberTier.Standard;

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalSpent { get; set; } = 0;

        /// <summary>Tổng tiền đã nạp (đã duyệt) — dùng cho xét hạng theo tỉ lệ nạp/chi.</summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalDeposit { get; set; } = 0;

        public string? AvatarUrl { get; set; }
    }
}
