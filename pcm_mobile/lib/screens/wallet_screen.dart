import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../models/wallet_transaction.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _apiService = ApiService();
  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).member;

    return Scaffold(
      appBar: AppBar(title: const Text('Ví của tôi')),
      body: _isLoading || user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                          Text('Số dư hiện tại',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16)),
                          Icon(Icons.account_balance_wallet,
                              color: Colors.white),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${user.walletBalance.toStringAsFixed(0)} đ',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

                // Transactions Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giao dịch gần đây',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                          onPressed: () {}, child: const Text('Xem tất cả')),
                    ],
                  ),
                ),

                // Transactions List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      // 0: Deposit, 1: Withdraw, 2: Payment, 3: Refund, 4: Reward
                      final isPositive =
                          t.type == 0 || t.type == 3 || t.type == 4;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 5)
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPositive
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.description ?? 'Transaction',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    t.createdDate.toString().split('.')[0],
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isPositive ? '+' : '-'}${t.amount.abs().toStringAsFixed(0)}',
                              style: TextStyle(
                                color: isPositive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
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
