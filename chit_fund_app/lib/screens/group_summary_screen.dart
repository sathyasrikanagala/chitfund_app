import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GroupSummaryScreen extends StatefulWidget {
  const GroupSummaryScreen({super.key});

  @override
  State<GroupSummaryScreen> createState() => _GroupSummaryScreenState();
}

class _GroupSummaryScreenState extends State<GroupSummaryScreen> {
  List<Map<String, dynamic>> _groups = [];
  Map<String, double> _collectedByGroup = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  setState(() => _isLoading = true);
  final groups = await ApiService.getGroups();

  Map<String, double> collected = {};
  for (var group in groups) {
    final payments = await ApiService.getPayments(groupId: group['id']);
    collected[group['id']] = payments.fold(
        0.0, (sum, p) => sum + (p['amount'] as num));
  }

  setState(() {
    _groups = groups;
    _collectedByGroup = collected;
    _isLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Group Summary', style: TextStyle(color: Colors.white)),
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
          : _groups.isEmpty
              ? const Center(
                  child: Text('No chit groups yet.\nCreate a group first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final g = _groups[index];
                      final isCompleted = g['status'] == 'Completed';
                      final collected = _collectedByGroup[g['id']] ?? 0;
                      final totalExpected =
                          (g['amount'] as num) * (g['total_members'] as num);
                      final pending = totalExpected - collected;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                  Expanded(
                                    child: Text(g['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? Colors.blue.shade50
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: isCompleted
                                              ? Colors.blue
                                              : Colors.green),
                                    ),
                                    child: Text(g['status'],
                                        style: TextStyle(
                                            color: isCompleted
                                                ? Colors.blue
                                                : Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _statItem('Members',
                                      '${g['total_members']}', Colors.purple),
                                  _statItem('Installment',
                                      '₹${(g['amount'] as num).toStringAsFixed(0)}',
                                      Colors.blue),
                                  _statItem('Collected',
                                      '₹${collected.toStringAsFixed(0)}',
                                      Colors.green),
                                  _statItem('Pending',
                                      '₹${pending.toStringAsFixed(0)}',
                                      Colors.orange),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}