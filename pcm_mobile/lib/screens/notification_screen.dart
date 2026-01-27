import 'package:flutter/material.dart';
import '../services/signalr_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final SignalRService _signalRService = SignalRService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: StreamBuilder<String>(
        stream: _signalRService.notificationStream,
        builder: (context, snapshot) {
          final notifications = _signalRService.notifications;
          
          if (notifications.isEmpty) {
            return const Center(child: Text('Chưa có thông báo nào'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              final isRead = n['isRead'] as bool;

              return Container(
                color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey : Colors.deepPurple,
                    child: const Icon(Icons.notifications, color: Colors.white, size: 20),
                  ),
                  title: Text(n['title'] as String, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(n['body'] as String),
                      const SizedBox(height: 4),
                      Text(n['time'].toString().split('.')[0], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      n['isRead'] = true;
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
