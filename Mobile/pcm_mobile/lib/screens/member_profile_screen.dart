import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Màn xem profile thành viên khác — GET /api/members/{id}/profile
class MemberProfileScreen extends StatefulWidget {
  final int memberId;

  const MemberProfileScreen({super.key, required this.memberId});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _apiService.getMemberProfile(widget.memberId);
      if (mounted) {
        setState(() {
          _data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _tierName(dynamic tier) {
    if (tier == null) return '—';
    final t = tier is num ? tier.toInt() : 0;
    switch (t) {
      case 1: return 'Bạc';
      case 2: return 'Vàng';
      case 3: return 'Kim cương';
      default: return 'Đồng';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ thành viên')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ thành viên')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text('Không tải được hồ sơ.', style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
              ],
            ),
          ),
        ),
      );
    }
    final d = _data ?? {};
    final fullName = d['fullName']?.toString() ?? '—';
    final tier = d['tier'];
    final walletBalance = (d['walletBalance'] as num?)?.toDouble();
    final totalDeposit = (d['totalDeposit'] as num?)?.toDouble();
    final rankLevel = (d['rankLevel'] as num?)?.toDouble();
    final email = d['email']?.toString();
    final phone = d['phoneNumber']?.toString();
    final rankHistory = d['rankHistory'] is List ? d['rankHistory'] as List : <dynamic>[];
    final matchHistory = d['matchHistory'] is List ? d['matchHistory'] as List : <dynamic>[];

    return Scaffold(
      appBar: AppBar(title: Text(fullName)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  backgroundImage: d['avatarUrl'] != null ? NetworkImage(d['avatarUrl'].toString()) : null,
                  child: d['avatarUrl'] == null ? Text(fullName.isNotEmpty ? fullName[0] : '?', style: TextStyle(fontSize: 36, color: Theme.of(context).colorScheme.primary)) : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Hạng: ${_tierName(tier)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                ),
              ),
              const SizedBox(height: 24),
              _infoTile('Họ tên', fullName),
              if (rankLevel != null) _infoTile('DUPR', rankLevel.toStringAsFixed(2)),
              if (walletBalance != null) _infoTile('Số dư ví', '${walletBalance.toStringAsFixed(0)} đ'),
              if (totalDeposit != null) _infoTile('Tổng nạp', '${(totalDeposit / 1000).toStringAsFixed(0)}k đ'),
              if (email != null && email.isNotEmpty) _infoTile('Email', email),
              if (phone != null && phone.isNotEmpty) _infoTile('SĐT', phone),
              if (rankHistory.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Lịch sử hạng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...rankHistory.take(10).map((e) {
                  final map = e is Map ? e as Map<String, dynamic> : <String, dynamic>{};
                  return ListTile(
                    dense: true,
                    title: Text(map['description']?.toString() ?? '—'),
                    trailing: Text(map['tier']?.toString() ?? ''),
                  );
                }),
              ],
              if (matchHistory.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Lịch sử đấu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...matchHistory.take(10).map((e) {
                  final map = e is Map ? e as Map<String, dynamic> : <String, dynamic>{};
                  return ListTile(
                    dense: true,
                    title: Text(map['opponent']?.toString() ?? map['result']?.toString() ?? '—'),
                    subtitle: Text(map['date']?.toString() ?? ''),
                  );
                }),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
