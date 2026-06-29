import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DailyCollectionScreen extends StatefulWidget {
  const DailyCollectionScreen({super.key});

  @override
  State<DailyCollectionScreen> createState() => _DailyCollectionScreenState();
}

class _DailyCollectionScreenState extends State<DailyCollectionScreen> {
  List<Map<String, dynamic>> _payments = [];
  Map<String, dynamic> _membersById = {};
  Map<String, dynamic> _groupsById = {};
  bool _isLoading = true;
  bool _showAllTime = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  setState(() => _isLoading = true);
  final allPayments = await ApiService.getPayments();
  final members = await ApiService.getMembers();
  final groups = await ApiService.getGroups();

  final payments = _showAllTime
      ? allPayments
      : allPayments.where((p) {
          final paidDate = DateTime.parse(p['paid_at']);
          final today = DateTime.now();
          return paidDate.year == today.year &&
              paidDate.month == today.month &&
              paidDate.day == today.day;
        }).toList();

  setState(() {
    _payments = payments;
    _membersById = {for (var m in members) m['id']: m};
    _groupsById = {for (var g in groups) g['id']: g};
    _isLoading = false;
  });
}

  String _formatDateTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      if (_showAllTime) {
        return '${dt.day} ${months[dt.month - 1]}, $hour:$minute $ampm';
      }
      return '$hour:$minute $ampm';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCollected = _payments.fold(
        0.0, (sum, p) => sum + (p['amount'] as num));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Collection Report',
            style: TextStyle(color: Colors.white)),
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
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _toggleButton('Today', !_showAllTime, () {
                          setState(() => _showAllTime = false);
                          _loadData();
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _toggleButton('All Time', _showAllTime, () {
                          setState(() => _showAllTime = true);
                          _loadData();
                        }),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_showAllTime ? 'All Time' : 'Today',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _summaryBox('Collected',
                              '₹${totalCollected.toStringAsFixed(0)}',
                              Colors.green),
                          const SizedBox(width: 8),
                          _summaryBox('Payments',
                              '${_payments.length}', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _payments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payments_outlined,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                  _showAllTime
                                      ? 'No collections yet'
                                      : 'No collections today',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _payments.length,
                            itemBuilder: (context, index) {
                              final p = _payments[index];
                              final member = _membersById[p['member_id']];
                              final group = _groupsById[p['group_id']];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade50,
                                    child: const Icon(Icons.check,
                                        color: Colors.green),
                                  ),
                                  title: Text(member?['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      '${group?['name'] ?? ''} • ${p['payment_type']}',
                                      style: const TextStyle(fontSize: 12)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          '₹${(p['amount'] as num).toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green)),
                                      Text(_formatDateTime(p['paid_at']),
                                          style: const TextStyle(
                                              fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _toggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1565C0) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _summaryBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}