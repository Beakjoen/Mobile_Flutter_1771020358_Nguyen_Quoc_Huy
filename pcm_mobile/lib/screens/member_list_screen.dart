import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/member.dart';

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
        _members = (res.data as List).map((e) => Member.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final m = _members[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Text(m.fullName[0], style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Rank: ${m.rankLevel.toStringAsFixed(2)}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                                m.tier == 3
                                    ? "Diamond"
                                    : (m.tier == 2 ? "Gold" : (m.tier == 1 ? "Silver" : "Standard")),
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          onTap: () {
                            // TODO: Show member profile detail
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
