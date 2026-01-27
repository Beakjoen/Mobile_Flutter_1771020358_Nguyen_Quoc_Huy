import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'booking_screen.dart';
import 'tournament_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import '../providers/user_provider.dart';
import '../services/signalr_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> _buildScreens() => [
    const HomeScreen(embedded: true),
    const BookingScreen(embedded: true),
    const TournamentScreen(embedded: true),
    const WalletScreen(embedded: true),
    const ProfileScreen(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Consumer<UserProvider>(
          builder: (_, up, __) {
            final u = up.member;
            if (u == null) return const SizedBox.shrink();
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                  child: u.avatarUrl == null ? Text(u.fullName.isNotEmpty ? u.fullName[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 18)) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${(u.walletBalance / 1000).toStringAsFixed(0)}k đ', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          StreamBuilder<String>(
            stream: SignalRService().notificationStream,
            builder: (_, __) {
              final n = SignalRService().notifications.where((e) => e['isRead'] != true).length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                  ),
                  if (n > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Center(child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 10))),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Consumer<UserProvider>(
          builder: (_, up, __) {
            final u = up.member;
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white24,
                        backgroundImage: u?.avatarUrl != null ? NetworkImage(u!.avatarUrl!) : null,
                        child: u == null || u.avatarUrl == null ? Text(u?.fullName.isNotEmpty == true ? u!.fullName[0] : '?', style: const TextStyle(fontSize: 28, color: Colors.white)) : null,
                      ),
                      const SizedBox(height: 8),
                      Text(u?.fullName ?? 'Khách', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      if (u != null) Text('${(u.walletBalance / 1000).toStringAsFixed(0)}k đ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                _drawerTile(context, Icons.home, 'Trang chủ', 0),
                _drawerTile(context, Icons.calendar_today, 'Lịch đặt sân', 1),
                _drawerTile(context, Icons.emoji_events, 'Giải đấu', 2),
                _drawerTile(context, Icons.account_balance_wallet, 'Ví', 3),
                _drawerTile(context, Icons.person, 'Cá nhân', 4),
                if (u?.roles.contains('Admin') == true) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Quản lý'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/admin');
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Đặt sân'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_tennis), label: 'Giải đấu'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Ví'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }

  Widget _drawerTile(BuildContext context, IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: _currentIndex == index,
      onTap: () {
        Navigator.pop(context);
        setState(() => _currentIndex = index);
      },
    );
  }
}
