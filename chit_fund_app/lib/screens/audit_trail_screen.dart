import 'package:flutter/material.dart';

class AuditTrailScreen extends StatelessWidget {
  const AuditTrailScreen({super.key});

  final List<Map<String, dynamic>> _logs = const [
    {'action': 'Payment Collected', 'detail': 'Ravi Kumar • ₹5,000 • Group A', 'time': '10:30 AM', 'icon': Icons.payments, 'color': Colors.green},
    {'action': 'Member Added', 'detail': 'Padma Bai • Nalgonda', 'time': '09:15 AM', 'icon': Icons.person_add, 'color': Colors.blue},
    {'action': 'Prize Recorded', 'detail': 'Ravi Kumar • Group A • ₹90,000', 'time': 'Yesterday 3:00 PM', 'icon': Icons.emoji_events, 'color': Colors.amber},
    {'action': 'Group Created', 'detail': 'Group B - 2000 • 10 members', 'time': 'Yesterday 11:00 AM', 'icon': Icons.group_add, 'color': Colors.purple},
    {'action': 'Payment Collected', 'detail': 'Lakshmi Devi • ₹2,000 • Group B', 'time': 'Yesterday 10:00 AM', 'icon': Icons.payments, 'color': Colors.green},
    {'action': 'Login', 'detail': 'Admin logged in', 'time': 'Yesterday 9:00 AM', 'icon': Icons.login, 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Audit Trail',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final log = _logs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    (log['color'] as Color).withOpacity(0.15),
                child: Icon(log['icon'] as IconData,
                    color: log['color'] as Color, size: 20),
              ),
              title: Text(log['action'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(log['detail'],
                  style: const TextStyle(fontSize: 12)),
              trailing: Text(log['time'],
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
            ),
          );
        },
      ),
    );
  }
}