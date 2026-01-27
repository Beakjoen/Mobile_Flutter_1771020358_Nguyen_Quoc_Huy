using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models
{
    [Table("358_Tournaments")]
    public class Tournament
    {
        [Key]
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }

        public TournamentFormat Format { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal EntryFee { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal PrizePool { get; set; }

        public TournamentStatus Status { get; set; } = TournamentStatus.Open;

        public string? Settings { get; set; } // JSON string
    }

    [Table("358_TournamentParticipants")]
    public class TournamentParticipant
    {
        [Key]
        public int Id { get; set; }

        public int TournamentId { get; set; }
        [ForeignKey("TournamentId")]
        public Tournament? Tournament { get; set; }

        public int MemberId { get; set; }
        [ForeignKey("MemberId")]
        public Member? Member { get; set; }

        public string? TeamName { get; set; }
        public bool PaymentStatus { get; set; } // True if paid
    }
}
