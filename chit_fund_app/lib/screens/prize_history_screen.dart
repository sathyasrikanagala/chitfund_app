import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PrizeHistoryScreen extends StatefulWidget {
  const PrizeHistoryScreen({super.key});

  @override
  State<PrizeHistoryScreen> createState() => _PrizeHistoryScreenState();
}

class _PrizeHistoryScreenState extends State<PrizeHistoryScreen> {
  List<Map<String, dynamic>> _prizes = [];
  Map<String, dynamic> _membersById = {};
  Map<String, dynamic> _groupsById = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  setState(() => _isLoading = true);
  final members = await ApiService.getMembers();
  final groups = await ApiService.getGroups();
  final prizes = await ApiService.getPrizes();

  setState(() {
    _prizes = prizes;
    _membersById = {for (var m in members) m['id']: m};
    _groupsById = {for (var g in groups) g['id']: g};
    _isLoading = false;
  });
}

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Prize History', style: TextStyle(color: Colors.white)),
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
          : _prizes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No prizes recorded yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _prizes.length,
                    itemBuilder: (context, index) {
                      final p = _prizes[index];
                      final winner = _membersById[p['member_id']];
                      final group = _groupsById[p['group_id']];
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
                                  Row(
                                    children: [
                                      const Icon(Icons.emoji_events,
                                          color: Colors.amber, size: 20),
                                      const SizedBox(width: 8),
                                      Text(winner?['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ],
                                  ),
                                  Text(_formatDate(p['prize_date']),
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(group?['name'] ?? '',
                                  style: const TextStyle(color: Colors.grey)),
                              Text(
                                  'Installment #${p['installment_number']} • ${p['draw_method'] ?? ''}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _prizeItem('Chit Value',
                                      '₹${(p['chit_value'] as num).toStringAsFixed(0)}',
                                      Colors.blue),
                                  _prizeItem('Discount',
                                      '₹${(p['discount_amount'] as num).toStringAsFixed(0)}',
                                      Colors.orange),
                                  _prizeItem('Commission',
                                      '₹${(p['commission_amount'] as num).toStringAsFixed(0)}',
                                      Colors.red),
                                  _prizeItem('Net Payout',
                                      '₹${(p['net_payout'] as num).toStringAsFixed(0)}',
                                      Colors.green),
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

  Widget _prizeItem(String label, String value, Color color) {
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