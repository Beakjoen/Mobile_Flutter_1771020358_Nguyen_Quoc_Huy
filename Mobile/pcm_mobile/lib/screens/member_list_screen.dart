import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/member.dart';
import 'member_profile_screen.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Member> _members = [];
  bool _isLoading = true;
  int? _filterTier; // null = Tất cả, 0 = Đồng, 1 = Bạc, 2 = Vàng, 3 = Kim cương

  List<Member> get _filteredMembers {
    if (_filterTier == null) return _members;
    return _members.where((m) => m.tier == _filterTier).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getMembers(search: search);
      setState(() {
        final raw = res.data;
        final list = (raw is Map && raw['items'] != null)
            ? (raw['items'] as List)
            : (raw as List);
        _members = list.map((e) => Member.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _tierLabel(int t) {
    switch (t) {
      case 1: return 'Bạc';
      case 2: return 'Vàng';
      case 3: return 'Kim cương';
      default: return 'Đồng';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMembers;
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách thành viên')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thành viên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadData();
                  },
                ),
              ),
              onSubmitted: (val) => _loadData(search: val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: _filterTier == null,
                    onSelected: (_) => setState(() => _filterTier = null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(label: const Text('Đồng'), selected: _filterTier == 0, onSelected: (_) => setState(() => _filterTier = 0)),
                  const SizedBox(width: 8),
                  FilterChip(label: const Text('Bạc'), selected: _filterTier == 1, onSelected: (_) => setState(() => _filterTier = 1)),
                  const SizedBox(width: 8),
                  FilterChip(label: const Text('Vàng'), selected: _filterTier == 2, onSelected: (_) => setState(() => _filterTier = 2)),
                  const SizedBox(width: 8),
                  FilterChip(label: const Text('Kim cương'), selected: _filterTier == 3, onSelected: (_) => setState(() => _filterTier = 3)),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final m = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                            child: m.avatarUrl == null ? Text(m.fullName.isNotEmpty ? m.fullName[0] : '?', style: const TextStyle(color: Colors.white)) : null,
                          ),
                          title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Rank: ${m.rankLevel.toStringAsFixed(2)} · ${_tierLabel(m.tier)}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MemberProfileScreen(memberId: m.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
