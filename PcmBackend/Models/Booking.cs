using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models
{
    [Table("358_Bookings")]
    public class Booking
    {
        [Key]
        public int Id { get; set; }

        public int CourtId { get; set; }
        [ForeignKey("CourtId")]
        public Court? Court { get; set; }

        public int MemberId { get; set; }
        [ForeignKey("MemberId")]
        public Member? Member { get; set; }

        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalPrice { get; set; }

        public int? TransactionId { get; set; }
        [ForeignKey("TransactionId")]
        public WalletTransaction? Transaction { get; set; }

        public bool IsRecurring { get; set; }
        public string? RecurrenceRule { get; set; } // e.g. "Weekly;Tue,Thu"
        public int? ParentBookingId { get; set; } // Self-referencing FK logic handled in business layer mostly

        public BookingStatus Status { get; set; } = BookingStatus.PendingPayment;

        public DateTime CreatedDate { get; set; } = DateTime.Now;
    }
}
