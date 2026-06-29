import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/due_calculator.dart';

class OutstandingDuesScreen extends StatefulWidget {
  const OutstandingDuesScreen({super.key});

  @override
  State<OutstandingDuesScreen> createState() => _OutstandingDuesScreenState();
}

class _OutstandingDuesScreenState extends State<OutstandingDuesScreen> {
  List<Map<String, dynamic>> _dues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

Future<void> _loadData() async {
  setState(() => _isLoading = true);
  final groups = await ApiService.getGroups();

  List<Map<String, dynamic>> duesList = [];

  for (var group in groups) {
    final groupMembers = await ApiService.getGroupMembers(group['id']);
    final payments = await ApiService.getPayments(groupId: group['id']);

    for (var member in groupMembers) {
      final memberId = member['id'];
      final memberPayments =
          payments.where((p) => p['member_id'] == memberId);
      final totalPaid = memberPayments.fold(
          0.0, (sum, p) => sum + (p['amount'] as num));

      final pending = DueCalculator.pendingAmount(
        groupStartDate: group['start_date'],
        groupFrequency: group['frequency'],
        installmentAmount: (group['amount'] as num).toDouble(),
        totalPaid: totalPaid,
      );

      if (pending > 0) {
        duesList.add({
          'member': member,
          'group': group,
          'pending': pending,
        });
      }
    }
  }

  setState(() {
    _dues = duesList;
    _isLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Outstanding Dues', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text('All members are up to date!',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text(
                          'Make sure members are added to their\nchit groups for accurate due tracking.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _dues.length,
                    itemBuilder: (context, index) {
                      final due = _dues[index];
                      final member = due['member'];
                      final group = due['group'];
                      final pending = due['pending'] as double;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(member['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange),
                                    ),
                                    child: Text(group['name'],
                                        style: const TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(member['village'] ?? '',
                                  style: const TextStyle(color: Colors.grey)),
                              Text(member['mobile'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 12),
                              Text('Due: ₹${pending.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}