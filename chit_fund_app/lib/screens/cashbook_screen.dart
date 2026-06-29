import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CashbookScreen extends StatefulWidget {
  const CashbookScreen({super.key});

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  bool _showAllTime = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
  setState(() => _isLoading = true);
  final allEntries = await ApiService.getCashEntries();

  final entries = _showAllTime
      ? allEntries
      : allEntries.where((e) {
          final entryDate = DateTime.parse(e['entry_date']);
          final today = DateTime.now();
          return entryDate.year == today.year &&
              entryDate.month == today.month &&
              entryDate.day == today.day;
        }).toList();

  setState(() {
    _entries = entries;
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
    final totalIn = _entries
        .where((e) => e['type'] == 'in')
        .fold(0.0, (sum, e) => sum + (e['amount'] as num));
    final totalOut = _entries
        .where((e) => e['type'] == 'out')
        .fold(0.0, (sum, e) => sum + (e['amount'] as num));
    final balance = totalIn - totalOut;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Cashbook', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadEntries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Toggle
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _toggleButton('Today', !_showAllTime, () {
                          setState(() => _showAllTime = false);
                          _loadEntries();
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _toggleButton('All Time', _showAllTime, () {
                          setState(() => _showAllTime = true);
                          _loadEntries();
                        }),
                      ),
                    ],
                  ),
                ),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _summaryBox(
                          'Total In', '₹${totalIn.toStringAsFixed(0)}', Colors.green),
                      const SizedBox(width: 8),
                      _summaryBox(
                          'Total Out', '₹${totalOut.toStringAsFixed(0)}', Colors.red),
                      const SizedBox(width: 8),
                      _summaryBox(
                          'Balance', '₹${balance.toStringAsFixed(0)}', Colors.blue),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_showAllTime ? 'All Transactions' : 'Today',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('${_entries.length} transactions',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),

                Expanded(
                  child: _entries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                  _showAllTime
                                      ? 'No transactions yet'
                                      : 'No transactions today',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadEntries,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _entries.length,
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              final isIn = entry['type'] == 'in';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isIn
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    child: Icon(
                                      isIn
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: isIn ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  title: Text(entry['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  subtitle: Text(
                                      '${entry['description'] ?? ''} • ${entry['payment_mode'] ?? ''}',
                                      style: const TextStyle(fontSize: 12)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isIn ? '+' : '-'}₹${(entry['amount'] as num).toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: isIn ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(_formatDateTime(entry['entry_date'] ?? ''),
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
                    color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}