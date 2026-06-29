import 'package:flutter/material.dart';
import 'cashbook_screen.dart';
import 'outstanding_dues_screen.dart';
import 'defaulters_screen.dart';
import 'group_summary_screen.dart';
import 'daily_collection_screen.dart';
import 'member_ledger_screen.dart';
import 'prize_history_screen.dart';
import 'audit_trail_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> reports = [
      {
        'title': 'Daily Collection Report',
        'subtitle': 'Today\'s collections by member',
        'icon': Icons.payments,
        'color': Colors.green,
        'screen': 'daily',

      },
      {
        'title': 'Daily Cashbook',
        'subtitle': 'Cash in and out for today',
        'icon': Icons.book,
        'color': Colors.blue,
        'screen': 'cashbook',
      },
      {
        'title': 'Outstanding Dues',
        'subtitle': 'Members with pending payments',
        'icon': Icons.warning,
        'color': Colors.orange,
        'screen': 'dues',
      },
      {
        'title': 'Member Ledger',
        'subtitle': 'Full payment history per member',
        'icon': Icons.person,
        'color': Colors.purple,
        'screen': 'ledger',

      },
      {
        'title': 'Prize History',
        'subtitle': 'All prize disbursements',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
        'screen': 'prizes',
      },
      {
        'title': 'Defaulters Report',
        'subtitle': 'Members who missed payments',
        'icon': Icons.person_off,
        'color': Colors.red,
        'screen': 'defaulters',
      },
      {
        'title': 'Group Summary',
        'subtitle': 'Status of all chit groups',
        'icon': Icons.group_work,
        'color': Colors.teal,
        'screen': 'groupsummary',
      },
      {
        'title': 'Audit Trail',
        'subtitle': 'All changes and actions log',
        'icon': Icons.history,
        'color': Colors.grey,
        'screen': 'audit',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Reports', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: (report['color'] as Color).withOpacity(0.15),
                child: Icon(report['icon'] as IconData, color: report['color'] as Color),
              ),
              title: Text(report['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(report['subtitle'], style: const TextStyle(fontSize: 12)),
              trailing: Icon(
                report['screen'] != null ? Icons.arrow_forward_ios : Icons.lock_clock,
                size: 14,
                color: Colors.grey,
              ),
              onTap: () {
                switch (report['screen']) {
                  case 'cashbook':
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const CashbookScreen()));
                    break;
                  case 'dues':
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const OutstandingDuesScreen()));
                    break;
                  case 'defaulters':
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const DefaultersScreen()));
                    break;
                  case 'groupsummary':
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const GroupSummaryScreen()));
                    break;
                  case 'daily':
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const DailyCollectionScreen()));
                    break;
                  case 'ledger':
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const MemberLedgerScreen()));
                    break;
                  case 'prizes':
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const PrizeHistoryScreen()));
                    break;
                  case 'audit':
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const AuditTrailScreen()));
                    break;
                  default:
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon')),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}