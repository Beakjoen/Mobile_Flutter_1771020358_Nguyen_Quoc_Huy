import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tournament.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class TournamentDetailScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isJoining = false;

  Future<void> _joinTournament() async {
    final teamNameController = TextEditingController();
    
    // Show dialog to enter team name
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tham gia giải đấu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Phí tham gia: ${widget.tournament.entryFee.toStringAsFixed(0)} đ'),
            const SizedBox(height: 16),
            TextField(
              controller: teamNameController,
              decoration: const InputDecoration(
                labelText: 'Tên đội / Tên hiển thị',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (teamNameController.text.isEmpty) return;
              Navigator.pop(context);
              _processJoin(teamNameController.text);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _processJoin(String teamName) async {
    setState(() => _isJoining = true);
    try {
      await _apiService.joinTournament(widget.tournament.id, teamName);
      
      // Update wallet
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).loadUser();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.tournament.name),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(text: 'Thông tin'),
              Tab(text: 'Nhánh đấu'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(),
            _buildBracketTab(),
          ],
        ),
        bottomNavigationBar: widget.tournament.status == 0
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isJoining ? null : _joinTournament,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    child: _isJoining
                        ? const CircularProgressIndicator()
                        : Text('Tham gia ngay (${widget.tournament.entryFee.toStringAsFixed(0)} đ)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.calendar_today, 'Thời gian',
              '${widget.tournament.startDate.toString().split(' ')[0]} - ${widget.tournament.endDate.toString().split(' ')[0]}'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.emoji_events, 'Giải thưởng', '${widget.tournament.prizePool.toStringAsFixed(0)} đ'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.attach_money, 'Phí tham gia', '${widget.tournament.entryFee.toStringAsFixed(0)} đ'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.info_outline, 'Thể thức', widget.tournament.format == 0 ? 'Loại trực tiếp (Knockout)' : 'Vòng tròn (Round Robin)'),
          const SizedBox(height: 24),
          const Text('Mô tả giải đấu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Giải đấu Pickleball thường niên quy tụ các tay vợt xuất sắc nhất khu vực. '
            'Cơ cấu giải thưởng hấp dẫn và cơ hội tích lũy điểm DUPR.',
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.deepPurple),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildBracketTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Sơ đồ thi đấu chưa được công bố', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Vui lòng quay lại sau khi giải đấu bắt đầu', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
