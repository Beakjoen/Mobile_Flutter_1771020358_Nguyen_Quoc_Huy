import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  Widget _buildBody(BuildContext context) {
    final user = Provider.of<UserProvider>(context).member;
    if (user == null) return const Center(child: Text("Chưa đăng nhập"));
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.deepPurple.shade100,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(user.fullName[0],
                          style: const TextStyle(
                              fontSize: 48, color: Colors.deepPurple))
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(blurRadius: 5, color: Colors.black12)
                      ]),
                  child: const Icon(Icons.camera_alt, color: Colors.deepPurple),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(user.fullName,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Hạng: ${user.rankLevel}',
                style: TextStyle(
                    color: Colors.amber.shade900, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),

            // Info Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                      Icons.person_outline, 'ID Người dùng', '#${user.id}'),
                  const Divider(height: 1),
                  _buildInfoTile(
                      Icons.star_outline,
                      'Hạng thành viên',
                      user.tier == 0
                          ? "Thường"
                          : (user.tier == 1
                              ? "Bạc"
                              : (user.tier == 2 ? "Vàng" : "Kim Cương"))),
                  const Divider(height: 1),
                  _buildInfoTile(Icons.account_balance_wallet_outlined,
                      'Số dư ví', '${user.walletBalance.toStringAsFixed(0)} đ'),
                  const Divider(height: 1),
                  _buildInfoTile(Icons.email_outlined, 'Email',
                      user.email ?? 'Chưa cập nhật'),
                  const Divider(height: 1),
                  _buildInfoTile(Icons.phone_outlined, 'Số điện thoại',
                      user.phoneNumber ?? 'Chưa cập nhật'),
                ],
              ),
            ),

            if (user.roles.contains("Admin") ||
                user.email?.startsWith("admin") == true) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin');
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Bảng điều khiển Admin',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Provider.of<UserProvider>(context, listen: false).logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Đăng xuất',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (embedded) return _buildBody(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ của tôi')),
      body: _buildBody(context),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.deepPurple),
      ),
      title:
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      trailing: Text(value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
