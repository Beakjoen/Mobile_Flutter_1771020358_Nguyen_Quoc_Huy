import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminDepositApprovalScreen extends StatefulWidget {
  const AdminDepositApprovalScreen({super.key});

  @override
  State<AdminDepositApprovalScreen> createState() => _AdminDepositApprovalScreenState();
}

class _AdminDepositApprovalScreenState extends State<AdminDepositApprovalScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _pendingDeposits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getPendingDeposits();
      setState(() {
        _pendingDeposits = res.data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approve(int id) async {
    try {
      await _apiService.approveDeposit(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt thành công')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _reject(int id) async {
    try {
      await _apiService.rejectDeposit(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt nạp tiền')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingDeposits.isEmpty
              ? const Center(child: Text('Không có yêu cầu nạp tiền nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingDeposits.length,
                  itemBuilder: (context, index) {
                    final item = _pendingDeposits[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.attach_money, color: Colors.white),
                        ),
                        title: Text('${item['memberName']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Số tiền: ${(item['amount'] as num).toStringAsFixed(0)} đ',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            Text('Thời gian: ${item['createdDate'].toString().split('.')[0]}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approve(item['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _reject(item['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
