namespace PcmBackend.Models;

/// <summary>
/// Hạng thành viên (Tier): xét theo mốc tổng tiền đã nạp (TotalDeposit).
/// Bạc 1M, Vàng 5M, Kim cương 10M.
/// </summary>
public static class MemberTierHelper
{
    private const decimal SilverThreshold = 1_000_000m;   // 1 triệu
    private const decimal GoldThreshold = 5_000_000m;    // 5 triệu
    private const decimal DiamondThreshold = 10_000_000m; // 10 triệu

    /// <summary>Cập nhật hạng theo mốc nạp. Gọi khi thay đổi TotalDeposit (vd. Admin duyệt nạp).</summary>
    public static void UpdateTier(Member member)
    {
        member.Tier = member.TotalDeposit >= DiamondThreshold ? MemberTier.Diamond
            : member.TotalDeposit >= GoldThreshold ? MemberTier.Gold
            : member.TotalDeposit >= SilverThreshold ? MemberTier.Silver
            : MemberTier.Standard;
    }
}
