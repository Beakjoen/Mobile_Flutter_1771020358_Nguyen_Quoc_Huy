import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/member.dart';
import '../models/booking.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import 'notification_screen.dart';

/// Mốc nạp (đồng) → hạng. Dùng cho "Cách lên hạng" và progress.
const double kSilverDeposit = 1000000;
const double kGoldDeposit = 5000000;
const double kDiamondDeposit = 10000000;

class HomeScreen extends StatefulWidget {
  final bool embedded;

  const HomeScreen({super.key, this.embedded = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _leaderboard = [];
  bool _loadingLeaderboard = true;
  List<Booking> _upcomingBookings = [];
  bool _loadingUpcoming = true;
  int? _lastLoadedMemberId;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final res = await _apiService.getLeaderboard(top: 10);
      if (mounted) {
        setState(() {
          _leaderboard = res.data is List ? res.data as List : [];
          _loadingLeaderboard = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLeaderboard = false);
    }
  }

  Future<void> _loadUpcomingBookings(int? memberId) async {
    if (memberId == null) {
      if (mounted) setState(() => _loadingUpcoming = false);
      return;
    }
    if (mounted) setState(() => _loadingUpcoming = true);
    try {
      final now = DateTime.now();
      final to = now.add(const Duration(days: 14));
      final res = await _apiService.getCalendar(now, to);
      final list = res.data is List ? res.data as List : <dynamic>[];
      final bookings = list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).where((b) => b.memberId == memberId && b.startTime.isAfter(now) && b.status != 2).toList();
      bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (mounted) {
        setState(() {
          _upcomingBookings = bookings;
          _loadingUpcoming = false;
          _lastLoadedMemberId = memberId;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUpcoming = false);
    }
  }

  Widget _buildBody(BuildContext context) {
    final user = Provider.of<UserProvider>(context).member;
    final notifications = SignalRService().notifications;
    if (user == null) return const Center(child: CircularProgressIndicator());
    if (_lastLoadedMemberId != user.id) {
      _lastLoadedMemberId = user.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadUpcomingBookings(user.id);
      });
    }
    return RefreshIndicator(
      onRefresh: () async {
        Provider.of<UserProvider>(context, listen: false).loadUser();
        await _loadLeaderboard();
        await _loadUpcomingBookings(Provider.of<UserProvider>(context, listen: false).member?.id);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserCard(user),
            const SizedBox(height: 20),
            _buildTierProgress(user),
            const SizedBox(height: 20),
            _buildRankChart(),
            const SizedBox(height: 20),
            _buildUpcomingSchedule(user.id),
            const SizedBox(height: 20),
            _buildHowToRankUp(context),
            const SizedBox(height: 20),
            _buildLeaderboard(),
            const SizedBox(height: 20),
            _buildRecentNotifications(notifications),
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody(context);
    final notifications = SignalRService().notifications;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ PCM', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
              ),
              if (notifications.any((n) => n['isRead'] == false))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('${notifications.where((n) => n['isRead'] == false).length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildUserCard(Member user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6200EE), Color(0xFF9965f4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl as String) : null,
            child: user.avatarUrl == null ? Text('${user.fullName[0]}', style: const TextStyle(fontSize: 24, color: Colors.deepPurple)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Hạng: ${user.tierName}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                if (user.rankLevel > 0) ...[
                  const SizedBox(height: 4),
                  Text('DUPR: ${user.rankLevel}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Số dư', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                '${(user.walletBalance / 1000).toStringAsFixed(0)}k đ',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgress(Member user) {
    final d = user.totalDeposit;
    double nextThreshold = kSilverDeposit;
    String nextLabel = 'Bạc (1M)';
    if (d >= kDiamondDeposit) {
      nextThreshold = kDiamondDeposit;
      nextLabel = '—';
    } else if (d >= kGoldDeposit) {
      nextThreshold = kDiamondDeposit;
      nextLabel = 'Kim cương (10M)';
    } else if (d >= kSilverDeposit) {
      nextThreshold = kGoldDeposit;
      nextLabel = 'Vàng (5M)';
    }
    final progress = nextLabel == '—' ? 1.0 : (nextThreshold <= 0 ? 0.0 : (d / nextThreshold).clamp(0.0, 1.0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tiến trình hạng thành viên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              if (nextLabel != '—') Text('Mục tiêu: $nextLabel', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text('Đã nạp: ${(d / 1000).toStringAsFixed(0)}k đ', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildRankChart() {
    const topN = 6;
    final data = _leaderboard.take(topN).toList();
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: const Center(child: Text('Chưa có dữ liệu xếp hạng', style: TextStyle(color: Colors.grey))),
      );
    }
    final maxY = (data.map((e) => ((e['totalDeposit'] as num?) ?? 0).toDouble()).reduce((a, b) => a > b ? a : b) / 1000).clamp(1.0, double.infinity);
    final barGroups = List.generate(data.length, (i) {
      final deposit = ((data[i]['totalDeposit'] as num?) ?? 0).toDouble() / 1000;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: deposit,
            color: i < 3 ? Colors.amber : Theme.of(context).colorScheme.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    });
    return Container(
      padding: const EdgeInsets.all(16),
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Biểu đồ xếp hạng (top nạp tiền)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex < 0 || groupIndex >= data.length) return BarTooltipItem('', const TextStyle(fontSize: 12));
                      final name = data[groupIndex]['fullName'] ?? '—';
                      final k = (rod.toY).toStringAsFixed(0);
                      return BarTooltipItem('$name\n${k}k đ', const TextStyle(color: Colors.white, fontSize: 12));
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) => Text('${v.toInt() + 1}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) => Text('${v.toInt()}k', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      reservedSize: 28,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: barGroups,
              ),
              swapAnimationDuration: const Duration(milliseconds: 200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSchedule(int memberId) {
    if (_lastLoadedMemberId != memberId || _loadingUpcoming) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: const Center(child: SizedBox(height: 40, width: 40, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Lịch thi đấu sắp tới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_upcomingBookings.isNotEmpty)
              Text('${_upcomingBookings.length} lịch', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 12),
        if (_upcomingBookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Center(child: Text('Chưa có lịch đặt sân nào', style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
          )
        else
          ..._upcomingBookings.take(5).map((b) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2), child: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary)),
                  title: Text(b.court?.name ?? 'Sân', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${DateFormat('dd/MM').format(b.startTime)} · ${DateFormat('HH:mm').format(b.startTime)} - ${DateFormat('HH:mm').format(b.endTime)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              )),
      ],
    );
  }

  Widget _buildHowToRankUp(BuildContext context) {
    return InkWell(
      onTap: () => _showHowToRankUp(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cách lên hạng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                  const SizedBox(height: 4),
                  Text('Bạc 1M · Vàng 5M · Kim cương 10M (tổng nạp đã duyệt). Chạm để xem chi tiết.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade800)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.amber.shade700),
          ],
        ),
      ),
    );
  }

  void _showHowToRankUp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cách lên hạng thành viên', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Hạng được tính theo tổng tiền nạp đã được duyệt (Admin/Thủ quỹ duyệt yêu cầu nạp tiền).', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            _tierRow('Đồng', 'Mặc định', null),
            _tierRow('Bạc', '1.000.000 đ', Icons.emoji_events),
            _tierRow('Vàng', '5.000.000 đ', Icons.workspace_premium),
            _tierRow('Kim cương', '10.000.000 đ', Icons.diamond),
            const SizedBox(height: 16),
            const Text('Hạng Vàng trở lên: được đặt lịch định kỳ (T3, T5,…).', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _tierRow(String name, String condition, IconData? icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 22, color: Colors.amber.shade700),
          if (icon != null) const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
          Text(condition, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Top nạp tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Bảng xếp hạng', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: _loadingLeaderboard
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
              : _leaderboard.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('Chưa có dữ liệu')))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _leaderboard.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final e = _leaderboard[i];
                        final name = e['fullName'] ?? '—';
                        final deposit = ((e['totalDeposit'] as num?) ?? 0).toDouble();
                        final tier = e['tier'] ?? 0;
                        String tierName = 'Đồng';
                        if (tier == 1) tierName = 'Bạc';
                        else if (tier == 2) tierName = 'Vàng';
                        else if (tier == 3) tierName = 'Kim cương';
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: i < 3 ? Colors.amber.shade100 : Colors.grey.shade200,
                            child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: i < 3 ? Colors.amber.shade900 : Colors.grey.shade700)),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(tierName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          trailing: Text('${(deposit / 1000).toStringAsFixed(0)}k đ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildRecentNotifications(List<dynamic> notifications) {
    if (notifications.isEmpty) return const SizedBox.shrink();
    final recent = notifications.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thông báo gần đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...recent.map((n) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (n['isRead'] as bool? ?? true) ? Colors.white : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: (n['isRead'] as bool?) == false ? Colors.blue : Colors.grey.shade300,
                  child: const Icon(Icons.notifications, color: Colors.white, size: 20),
                ),
                title: Text(n['body']?.toString() ?? '', style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(n['time']?.toString().split('.')[0] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
              ),
            )),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _quickCard(context, 'Giải đấu', Icons.emoji_events, Colors.amber, '/tournaments')),
            const SizedBox(width: 12),
            Expanded(child: _quickCard(context, 'Nạp tiền', Icons.account_balance_wallet, Colors.green, '/wallet')),
            const SizedBox(width: 12),
            Expanded(child: _quickCard(context, 'Đặt sân', Icons.calendar_today, Colors.blue, '/booking')),
          ],
        ),
      ],
    );
  }

  Widget _quickCard(BuildContext context, String label, IconData icon, Color color, String route) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
