namespace PcmBackend.Models
{
    public enum MemberTier
    {
        Standard,
        Silver,
        Gold,
        Diamond
    }

    public enum TransactionType
    {
        Deposit,
        Withdraw,
        Payment,
        Refund,
        Reward
    }

    public enum TransactionStatus
    {
        Pending,
        Completed,
        Rejected,
        Failed
    }

    public enum BookingStatus
    {
        PendingPayment,
        Confirmed,
        Cancelled,
        Completed,
        Holding // For Hold Slot feature
    }

    public enum TournamentFormat
    {
        RoundRobin,
        Knockout,
        Hybrid
    }

    public enum TournamentStatus
    {
        Open,
        Registering,
        DrawCompleted,
        Ongoing,
        Finished
    }

    public enum MatchStatus
    {
        Scheduled,
        InProgress,
        Finished
    }

    public enum WinningSide
    {
        Team1,
        Team2,
        Draw
    }
    
    public enum NotificationType
    {
        Info,
        Success,
        Warning
    }
}
