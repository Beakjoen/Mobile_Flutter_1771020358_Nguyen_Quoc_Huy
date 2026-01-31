import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final ApiService _apiService = ApiService();
  List<Challenge> _list = [];
  bool _loading = true;
  String? _filter; // null = all, mine, open, finished

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _apiService.getChallenges(filter: _filter);
      if (mounted) {
        setState(() {
          _list = (res.data as List).map((e) => Challenge.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _CreateChallengeForm(
        apiService: _apiService,
        onSuccess: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo kèo thách đấu!')));
          _load();
        },
        onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $msg'))),
      ),
    );
  }

  void _showDetailSheet(Challenge c) {
    final me = context.read<UserProvider>().member;
    if (me == null) return;
    final isChallenger = c.challengerId == me.id;
    final isOpponent = c.opponentId == me.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ChallengeDetailSheet(
        challenge: c,
        currentMemberId: me.id,
        isChallenger: isChallenger,
        isOpponent: isOpponent,
        onAccept: () async {
          try {
            await _apiService.acceptChallenge(c.id);
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chấp nhận thách đấu!')));
            _load();
          } on DioException catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.response?.data?.toString() ?? 'Lỗi')));
          }
        },
        onSetResult: (winnerId) async {
          try {
            await _apiService.setChallengeResult(c.id, winnerId: winnerId);
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật kết quả!')));
            _load();
          } on DioException catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.response?.data?.toString() ?? 'Lỗi')));
          }
        },
        onCancel: () async {
          try {
            await _apiService.cancelChallenge(c.id);
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy kèo!')));
            _load();
          } on DioException catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.response?.data?.toString() ?? 'Lỗi')));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thách đấu'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() { _filter = null; _load(); }),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Của tôi'),
                  selected: _filter == 'mine',
                  onSelected: (_) => setState(() { _filter = 'mine'; _load(); }),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Đang mở'),
                  selected: _filter == 'open',
                  onSelected: (_) => setState(() { _filter = 'open'; _load(); }),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Đã kết thúc'),
                  selected: _filter == 'finished',
                  onSelected: (_) => setState(() { _filter = 'finished'; _load(); }),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _list.isEmpty
                        ? const Center(child: Text('Chưa có kèo nào'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _list.length,
                            itemBuilder: (_, i) {
                              final c = _list[i];
                              return Card(
                                child: ListTile(
                                  title: Text('${c.challengerName ?? "?"} vs ${c.opponentName ?? "Chờ đối thủ"}'),
                                  subtitle: Text(
                                    '${c.stakeAmount.toStringAsFixed(0)} đ · ${_statusLabel(c.status)}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _showDetailSheet(c),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'challenges_fab',
        onPressed: _showCreateSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'Pending': return 'Chờ chấp nhận';
      case 'Accepted': return 'Đã chấp nhận';
      case 'Finished': return 'Đã kết thúc';
      case 'Cancelled': return 'Đã hủy';
      default: return s;
    }
  }
}

class _CreateChallengeForm extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onSuccess;
  final void Function(String msg) onError;

  const _CreateChallengeForm({required this.apiService, required this.onSuccess, required this.onError});

  @override
  State<_CreateChallengeForm> createState() => _CreateChallengeFormState();
}

class _CreateChallengeFormState extends State<_CreateChallengeForm> {
  final _formKey = GlobalKey<FormState>();
  final _stakeController = TextEditingController(text: '50000');
  final _messageController = TextEditingController();
  int? _opponentId;
  bool _submitting = false;

  @override
  void dispose() {
    _stakeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    final amount = double.tryParse(_stakeController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      widget.onError('Số tiền phải lớn hơn 0');
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.apiService.createChallenge(
        stakeAmount: amount,
        opponentId: _opponentId,
        message: _messageController.text.isEmpty ? null : _messageController.text,
      );
      widget.onSuccess();
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response!.data['title'] ?? e.response!.data) : e.response?.data?.toString();
      widget.onError(msg?.toString() ?? e.message ?? 'Lỗi');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tạo kèo thách đấu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stakeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Số tiền đặt cọc (đ)'),
                validator: (v) {
                  final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                  if (n == null || n <= 0) return 'Nhập số tiền > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Lời nhắn (tùy chọn)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Tạo kèo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeDetailSheet extends StatelessWidget {
  final Challenge challenge;
  final int currentMemberId;
  final bool isChallenger;
  final bool isOpponent;
  final VoidCallback onAccept;
  final void Function(int winnerId) onSetResult;
  final VoidCallback onCancel;

  const _ChallengeDetailSheet({
    required this.challenge,
    required this.currentMemberId,
    required this.isChallenger,
    required this.isOpponent,
    required this.onAccept,
    required this.onSetResult,
    required this.onCancel,
  });

  String _statusLabel(String s) {
    switch (s) {
      case 'Pending': return 'Chờ chấp nhận';
      case 'Accepted': return 'Đã chấp nhận';
      case 'Finished': return 'Đã kết thúc';
      case 'Cancelled': return 'Đã hủy';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Kèo #${challenge.id}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${challenge.challengerName ?? "?"} vs ${challenge.opponentName ?? "Chờ đối thủ"}'),
          Text('Tiền cọc: ${challenge.stakeAmount.toStringAsFixed(0)} đ', style: TextStyle(color: Colors.grey[600])),
          Text('Trạng thái: ${_statusLabel(challenge.status)}'),
          if (challenge.message != null && challenge.message!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Lời nhắn: ${challenge.message}'),
            ),
          if (challenge.isFinished && challenge.winnerName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Người thắng: ${challenge.winnerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 20),
          if (challenge.canAccept && isOpponent) ...[
            ElevatedButton(onPressed: onAccept, child: const Text('Chấp nhận thách đấu')),
            const SizedBox(height: 8),
          ],
          if (challenge.canSetResult && (isChallenger || isOpponent)) ...[
            const Text('Cập nhật kết quả (chọn người thắng):'),
            const SizedBox(height: 8),
            Row(
              children: [
                if (challenge.opponentId != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onSetResult(challenge.challengerId),
                      child: Text(challenge.challengerName ?? 'Challenger'),
                    ),
                  ),
                if (challenge.opponentId != null) const SizedBox(width: 8),
                if (challenge.opponentId != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onSetResult(challenge.opponentId!),
                      child: Text(challenge.opponentName ?? 'Opponent'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (challenge.canCancel && (isChallenger || isOpponent))
            TextButton(onPressed: onCancel, child: const Text('Hủy kèo')),
        ],
      ),
    );
  }
}
