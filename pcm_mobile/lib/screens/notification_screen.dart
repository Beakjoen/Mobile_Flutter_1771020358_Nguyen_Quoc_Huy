import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data
    final notifications = [
      {
        'title': 'Đặt sân thành công',
        'body': 'Bạn đã đặt sân Sân 1 thành công vào 18:00 hôm nay.',
        'time': '10 phút trước',
        'isRead': false,
      },
      {
        'title': 'Nhắc nhở',
        'body': 'Trận đấu giải Winter Cup của bạn sẽ bắt đầu trong 1 giờ tới.',
        'time': '1 giờ trước',
        'isRead': true,
      },
      {
        'title': 'Khuyến mãi',
        'body': 'Nạp tiền ngay để nhận thêm 20% giá trị thẻ nạp.',
        'time': '1 ngày trước',
        'isRead': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: ListView.builder(
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
                  Text(n['time'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              onTap: () {
                // Mark as read logic would go here
              },
            ),
          );
        },
      ),
    );
  }
}
