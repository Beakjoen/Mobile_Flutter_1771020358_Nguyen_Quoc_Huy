import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tournament.dart';
import '../models/tournament_match.dart';
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
  List<dynamic> _matches = [];
  bool _matchesLoading = true;
  int _participantsCount = 0;
  bool _currentUserJoined = false;
  bool _participantsLoading = true;
  List<dynamic> _participantsList = [];

  Future<void> _loadParticipants() async {
    if (!mounted) return;
    setState(() => _participantsLoading = true);
    try {
      final res = await _apiService.getTournamentParticipants(widget.tournament.id);
      final data = res.data is Map ? res.data as Map<String, dynamic> : null;
      if (mounted && data != null) {
        final raw = data['participants'];
        final list = raw is List ? raw : <dynamic>[];
        setState(() {
          _participantsCount = (data['count'] as num?)?.toInt() ?? list.length;
          _currentUserJoined = data['currentUserJoined'] == true;
          _participantsList = list;
          _participantsLoading = false;
        });
      } else if (mounted) {
        setState(() => _participantsLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _participantsLoading = false);
    }
  }

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
      if (!mounted) return;
      Provider.of<UserProvider>(context, listen: false).loadUser();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!')));
      setState(() => _currentUserJoined = true);
      _loadParticipants();
    } catch (e) {
      if (mounted) {
        String msg = 'Không thể tham gia. Vui lòng thử lại.';
        if (e is DioException && e.response?.statusCode == 400) {
          final body = e.response?.data;
          if (body is String && body.isNotEmpty) {
            msg = body; // Backend đã trả tiếng Việt
          } else if (body is Map) {
            final raw = (body['detail'] ?? body['message'] ?? body['title'])?.toString() ?? '';
            if (raw.isNotEmpty) msg = raw;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMatches();
    _loadParticipants();
  }

  Future<void> _loadMatches() async {
    setState(() => _matchesLoading = true);
    try {
      final res = await _apiService.getTournamentMatches(widget.tournament.id);
      if (mounted) {
        setState(() {
          _matches = (res.data as List).map((e) => TournamentMatch.fromJson(e)).toList();
          _matchesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _matchesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.tournament.name),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(text: 'Thông tin'),
              Tab(text: 'Bảng xếp hạng'),
              Tab(text: 'Nhánh đấu'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(),
            _buildStandingsTab(),
            _buildBracketTab(),
          ],
        ),
        bottomNavigationBar: (widget.tournament.status == 0 || widget.tournament.status == 1)
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _currentUserJoined
                      ? ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.grey.shade700,
                          ),
                          child: const Text('Đã tham gia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        )
                      : ElevatedButton(
                          onPressed: _isJoining ? null : _joinTournament,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          child: _isJoining
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
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
          if (!_participantsLoading) ...[
            const SizedBox(height: 16),
            _buildInfoRow(Icons.people, 'Số người đã đăng ký', '$_participantsCount người'),
            if (_currentUserJoined)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text('Bạn đã tham gia giải này', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                  ],
                ),
              ),
          ],
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

  Widget _buildStandingsTab() {
    if (_participantsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_participantsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Chưa có người đăng ký. Tổng: $_participantsCount',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadParticipants,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _participantsList.length,
        itemBuilder: (context, i) {
          final p = _participantsList[i];
          final map = p is Map ? p as Map<String, dynamic> : <String, dynamic>{};
          final rank = i + 1;
          final name = map['fullName'] ?? map['teamName'] ?? map['memberName'] ?? '—';
          final teamName = map['teamName']?.toString();
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: rank <= 3 ? Colors.amber.shade100 : Colors.grey.shade200,
                child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: rank <= 3 ? Colors.amber.shade900 : Colors.grey.shade700)),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: teamName != null && teamName.isNotEmpty ? Text(teamName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)) : null,
            ),
          );
        },
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
    if (_matchesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              widget.tournament.status == 0 || widget.tournament.status == 1
                  ? 'Chưa có lịch thi đấu. Admin tạo lịch sau khi đủ đăng ký.'
                  : 'Chưa có trận đấu nào.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matches.length,
        itemBuilder: (context, i) {
          final m = _matches[i] as TournamentMatch;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: m.isFinished ? Colors.green.shade100 : Colors.orange.shade100,
                child: Icon(
                  m.isFinished ? Icons.emoji_events : Icons.schedule,
                  color: m.isFinished ? Colors.green : Colors.orange,
                ),
              ),
              title: Text('${m.team1Name} ${m.scoreText} ${m.team2Name}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${m.roundName} · ${m.date} ${m.startTime}'),
              trailing: m.isFinished
                  ? Text('${m.score1}-${m.score2}', style: const TextStyle(fontWeight: FontWeight.bold))
                  : const Text('Chưa đấu', style: TextStyle(color: Colors.grey)),
            ),
          );
        },
      ),
    );
  }
}
