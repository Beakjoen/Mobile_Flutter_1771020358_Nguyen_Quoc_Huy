using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models
{
    [Table("358_WalletTransactions")]
    public class WalletTransaction
    {
        [Key]
        public int Id { get; set; }

        public int MemberId { get; set; }
        [ForeignKey("MemberId")]
        public Member? Member { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; } // + or -

        public TransactionType Type { get; set; }
        public TransactionStatus Status { get; set; } = TransactionStatus.Pending;

        public string? RelatedId { get; set; } // BookingId or TournamentId
        public string? Description { get; set; }
        public DateTime CreatedDate { get; set; } = DateTime.Now;
    }
}
