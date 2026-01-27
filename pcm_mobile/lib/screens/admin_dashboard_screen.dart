import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_deposit_approval_screen.dart';
import 'member_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  int _monthlyBookings = 0;
  List<dynamic> _revenueData = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final res = await _apiService.getAdminStats();
      setState(() {
        _monthlyBookings = res.data['monthlyBookings'];
        _revenueData = res.data['revenueChart'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bảng điều khiển Admin')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Booking tháng này',
                          _monthlyBookings.toString(),
                          Icons.calendar_month,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Doanh thu tháng',
                          _revenueData.isNotEmpty
                              ? '${(_revenueData.last['income'] as num).toStringAsFixed(0)} đ'
                              : '0 đ',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text('Quản lý nhanh',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Quick Actions Grid (Moved Up)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildAdminActionCard(
                        context,
                        'Quản lý Giải đấu',
                        Icons.emoji_events,
                        Colors.amber,
                        () => Navigator.pushNamed(context, '/tournaments'),
                      ),
                      _buildAdminActionCard(
                        context,
                        'Duyệt Nạp tiền',
                        Icons.account_balance_wallet,
                        Colors.green,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const AdminDepositApprovalScreen())),
                      ),
                      _buildAdminActionCard(
                        context,
                        'Quản lý Đặt sân',
                        Icons.calendar_month,
                        Colors.blue,
                        () => Navigator.pushNamed(context, '/booking'),
                      ),
                      _buildAdminActionCard(
                        context,
                        'Quản lý Thành viên',
                        Icons.people,
                        Colors.purple,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const MemberListScreen())),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Revenue Chart (Moved Down)
                  const Text('Biểu đồ Doanh thu (6 tháng gần nhất)',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.blueGrey,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              String type = rodIndex == 0 ? 'Thu' : 'Chi';
                              return BarTooltipItem(
                                '$type: ${rod.toY.toStringAsFixed(0)}',
                                const TextStyle(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 || value >= _revenueData.length)
                                  return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _revenueData[value.toInt()]['month']
                                        .toString()
                                        .split('/')[0],
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _revenueData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: (data['income'] as num).toDouble(),
                                color: Colors.green,
                                width: 12,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                              BarChartRodData(
                                toY: (data['expense'] as num).toDouble(),
                                color: Colors.red,
                                width: 12,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(Colors.green, 'Nạp tiền (Thu)'),
                      const SizedBox(width: 16),
                      _buildLegend(Colors.red, 'Chi tiêu (Chi)'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  double _getMaxY() {
    if (_revenueData.isEmpty) return 100;
    double max = 0;
    for (var item in _revenueData) {
      max = max > (item['income'] as num).toDouble()
          ? max
          : (item['income'] as num).toDouble();
      max = max > (item['expense'] as num).toDouble()
          ? max
          : (item['expense'] as num).toDouble();
    }
    return max * 1.2; // Add 20% buffer
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildAdminActionCard(BuildContext context, String title,
      IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
