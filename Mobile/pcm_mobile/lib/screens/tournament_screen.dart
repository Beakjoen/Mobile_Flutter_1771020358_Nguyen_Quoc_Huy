import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/api_service.dart';
import 'tournament_detail_screen.dart';

class TournamentScreen extends StatefulWidget {
  final bool embedded;

  const TournamentScreen({super.key, this.embedded = false});

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
      if (mounted) {
        setState(() {
          _tournaments =
              (res.data as List).map((e) => Tournament.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateTournamentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _CreateTournamentForm(
        apiService: _apiService,
        onSuccess: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã mở giải đấu!')));
          _loadData();
        },
        onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $msg'))),
      ),
    );
  }

  /// Backend TournamentStatus: 0=Open, 1=Registering, 2=DrawCompleted, 3=Ongoing, 4=Finished
  List<Tournament> _filterTournaments(int tabIndex) {
    if (tabIndex == 0) return _tournaments.where((t) => t.status == 0 || t.status == 1).toList(); // Đăng ký
    if (tabIndex == 1) return _tournaments.where((t) => t.status == 2 || t.status == 3).toList(); // Đang diễn ra
    return _tournaments.where((t) => t.status == 4).toList(); // Đã kết thúc
  }

  String _statusLabel(int status) {
    const labels = ['Mở đăng ký', 'Đăng ký', 'Bốc thăm', 'Đang diễn ra', 'Kết thúc'];
    return status >= 0 && status < labels.length ? labels[status] : 'N/A';
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.primary,
              child: TabBar(
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
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTournamentList(_filterTournaments(0)),
                  _buildTournamentList(_filterTournaments(1)),
                  _buildTournamentList(_filterTournaments(2)),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'tournament_create_fab',
            onPressed: _showCreateTournamentSheet,
            icon: const Icon(Icons.add),
            label: const Text('Mở giải đấu'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giải đấu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Mở giải đấu',
            onPressed: _showCreateTournamentSheet,
          ),
        ],
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
      body: _buildBody(context),
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
                          color: t.status == 0 || t.status == 1
                              ? Colors.green
                              : (t.status == 2 || t.status == 3 ? Colors.orange : Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel(t.status),
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

class _CreateTournamentForm extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onSuccess;
  final void Function(String) onError;

  const _CreateTournamentForm({
    required this.apiService,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_CreateTournamentForm> createState() => _CreateTournamentFormState();
}

class _CreateTournamentFormState extends State<_CreateTournamentForm> {
  final _nameController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  final _entryFeeController = TextEditingController(text: '200000');
  final _prizePoolController = TextEditingController(text: '1000000');
  int _format = 0; // 0: Knockout, 1: RoundRobin
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().add(const Duration(days: 7));
    _endDate = _startDate.add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _entryFeeController.dispose();
    _prizePoolController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      widget.onError('Nhập tên giải đấu');
      return;
    }
    final entryFee = double.tryParse(_entryFeeController.text.replaceAll(',', ''));
    final prizePool = double.tryParse(_prizePoolController.text.replaceAll(',', ''));
    if (entryFee == null || entryFee < 0) {
      widget.onError('Phí tham gia không hợp lệ');
      return;
    }
    if (prizePool == null || prizePool < 0) {
      widget.onError('Giải thưởng không hợp lệ');
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      widget.onError('Ngày kết thúc phải sau ngày bắt đầu');
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.apiService.createTournament(
        name: name,
        prizePool: prizePool,
        entryFee: entryFee,
        startDate: _startDate,
        endDate: _endDate,
        format: _format,
      );
      if (mounted) widget.onSuccess();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.response?.data?.toString() ?? e.message ?? '$e';
      if (mounted) widget.onError(msg);
    } catch (e) {
      if (mounted) widget.onError('$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mở giải đấu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tên giải đấu'),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text('Ngày bắt đầu: ${_startDate.toString().split(' ')[0]}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => _startDate = d);
            },
          ),
          ListTile(
            title: Text('Ngày kết thúc: ${_endDate.toString().split(' ')[0]}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => _endDate = d);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _entryFeeController,
            decoration: const InputDecoration(labelText: 'Phí tham gia (đ)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _prizePoolController,
            decoration: const InputDecoration(labelText: 'Giải thưởng (đ)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          const Text('Thể thức:', style: TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              Radio<int>(value: 0, groupValue: _format, onChanged: (v) => setState(() => _format = v!)),
              const Text('Loại trực tiếp'),
              const SizedBox(width: 24),
              Radio<int>(value: 1, groupValue: _format, onChanged: (v) => setState(() => _format = v!)),
              const Text('Vòng tròn'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Tạo giải đấu'),
            ),
          ),
        ],
      ),
    );
  }
}
