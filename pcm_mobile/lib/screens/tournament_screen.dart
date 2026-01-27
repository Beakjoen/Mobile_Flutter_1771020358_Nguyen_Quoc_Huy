import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/api_service.dart';
import 'tournament_detail_screen.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Tournament> _tournaments = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getTournaments();
      setState(() {
        _tournaments =
            (res.data as List).map((e) => Tournament.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Tournament> _filterTournaments(int status) {
    // 0: Open, 1: Ongoing, 2: Finished
    return _tournaments.where((t) => t.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giải đấu'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: 'Đăng ký'),
            Tab(text: 'Đang diễn ra'),
            Tab(text: 'Đã kết thúc'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTournamentList(_filterTournaments(0)), // Open
                _buildTournamentList(_filterTournaments(1)), // Ongoing
                _buildTournamentList(_filterTournaments(2)), // Finished
              ],
            ),
    );
  }

  Widget _buildTournamentList(List<Tournament> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Không có giải đấu nào'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final t = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        TournamentDetailScreen(tournament: t)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          t.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: t.status == 0
                              ? Colors.green
                              : (t.status == 1 ? Colors.orange : Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.status == 0
                              ? "Mở đăng ký"
                              : (t.status == 1 ? "Đang diễn ra" : "Kết thúc"),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Thời gian: ${t.startDate.toString().split(' ')[0]} - ${t.endDate.toString().split(' ')[0]}'),
                  const SizedBox(height: 4),
                  Text('Giải thưởng: ${t.prizePool.toStringAsFixed(0)} đ'),
                  const SizedBox(height: 4),
                  Text('Phí tham gia: ${t.entryFee.toStringAsFixed(0)} đ',
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
