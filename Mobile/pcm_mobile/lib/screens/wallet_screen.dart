import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../models/wallet_transaction.dart';

class WalletScreen extends StatefulWidget {
  final bool embedded;

  const WalletScreen({super.key, this.embedded = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

/// 0: Nạp, 1: Trừ (Payment/Withdraw), 3: Hoàn tiền (Refund)
class _WalletScreenState extends State<WalletScreen> {
  final ApiService _apiService = ApiService();
  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;
  int? _filterType; // null = Tất cả, 0 = Nạp, 1 = Trừ tiền, 3 = Hoàn tiền

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<UserProvider>(context, listen: false).loadUser();
      final res = await _apiService.getTransactions();
      _transactions =
          (res.data as List).map((e) => WalletTransaction.fromJson(e)).toList();
    } catch (e) {
      print('Error loading transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải giao dịch: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDepositDialog() {
    final amountController = TextEditingController();
    XFile? image;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nạp tiền vào ví'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VNĐ)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  try {
                    final picker = ImagePicker();
                    final picked =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setState(() => image = picked);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi chọn ảnh: $e')));
                  }
                },
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: image == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload,
                                size: 32, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tải lên bằng chứng thanh toán',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : Image.network(image!.path, fit: BoxFit.cover),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty) return;
              try {
                await _apiService.deposit(double.parse(amountController.text));
                Navigator.pop(context);

                // Refresh data
                _loadData();
                if (context.mounted) {
                  // Reload user to update balance in header
                  Provider.of<UserProvider>(context, listen: false).loadUser();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Yêu cầu nạp tiền đã được gửi')));
                }
              } catch (e) {
                Navigator.pop(context);
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  List<WalletTransaction> get _filteredTransactions {
    if (_filterType == null) return _transactions;
    return _transactions.where((t) => t.type == _filterType).toList();
  }

  Widget _buildBody(BuildContext context) {
    final user = Provider.of<UserProvider>(context).member;
    if (_isLoading || user == null) return const Center(child: CircularProgressIndicator());
    final filtered = _filteredTransactions;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38ef7d).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Số dư hiện tại', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Icon(Icons.account_balance_wallet, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${user.walletBalance.toStringAsFixed(0)} đ',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showDepositDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF11998e),
                      elevation: 0,
                    ),
                    child: const Text('Nạp tiền'),
                  ),
                ),
              ],
            ),
          ),
          // Transactions Header + Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lịch sử giao dịch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Tất cả', _filterType == null, () => setState(() => _filterType = null)),
                      const SizedBox(width: 8),
                      _filterChip('Nạp', _filterType == 0, () => setState(() => _filterType = 0)),
                      const SizedBox(width: 8),
                      _filterChip('Trừ tiền', _filterType == 1, () => setState(() => _filterType = 1)),
                      const SizedBox(width: 8),
                      _filterChip('Hoàn tiền', _filterType == 3, () => setState(() => _filterType = 3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Transactions List
          ...filtered.map((t) {
            final isPositive = t.type == 0 || t.type == 3 || t.type == 4;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.description ?? 'Giao dịch', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(t.createdDate.toString().split('.')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    '${isPositive ? '+' : '-'}${t.amount.abs().toStringAsFixed(0)}',
                    style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            );
          }),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('Không có giao dịch', style: TextStyle(color: Colors.grey.shade600))),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ví của tôi')),
      body: _buildBody(context),
    );
  }
}
