import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MemberLedgerScreen extends StatefulWidget {
  const MemberLedgerScreen({super.key});

  @override
  State<MemberLedgerScreen> createState() => _MemberLedgerScreenState();
}

class _MemberLedgerScreenState extends State<MemberLedgerScreen> {
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _payments = [];
  String? _selectedMemberId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
  final members = await ApiService.getMembers();
  final groups = await ApiService.getGroups();
  setState(() {
    _members = members;
    _groups = groups;
    _selectedMemberId = members.isNotEmpty ? members.first['id'] : null;
  });
  if (_selectedMemberId != null) await _loadLedger();
  setState(() => _isLoading = false);
}

  Future<void> _loadLedger() async {
  if (_selectedMemberId == null) return;
  final payments = await ApiService.getPayments(memberId: _selectedMemberId);
  setState(() {
    _payments = payments;
  });
}

  String _groupName(String groupId) {
    final group = _groups.firstWhere(
        (g) => g['id'] == groupId, orElse: () => {'name': 'Unknown'});
    return group['name'];
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
    final totalPaid = _payments.fold(
        0.0, (sum, p) => sum + (p['amount'] as num));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Member Ledger',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadLedger,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? const Center(
                  child: Text('No members found.\nAdd a member first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                )
              : Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedMemberId,
                        decoration: const InputDecoration(
                          labelText: 'Select Member',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        items: _members
                            .map((m) => DropdownMenuItem(
                                value: m['id'] as String,
                                child: Text(m['name'])))
                            .toList(),
                        onChanged: (val) async {
                          setState(() => _selectedMemberId = val);
                          await _loadLedger();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ledgerStat('Total Paid',
                              '₹${totalPaid.toStringAsFixed(0)}',
                              Colors.greenAccent),
                          _ledgerStat('Payments',
                              '${_payments.length}', Colors.amberAccent),
                          _ledgerStat('Pending', '₹0', Colors.white),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Full Payment History',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text('${_payments.length} transactions',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _payments.isEmpty
                          ? const Center(
                              child: Text('No transactions yet',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadLedger,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _payments.length,
                                itemBuilder: (context, index) {
                                  final p = _payments[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.green.shade50,
                                        child: const Icon(Icons.arrow_downward,
                                            color: Colors.green),
                                      ),
                                      title: Text(p['payment_type'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                          '${_groupName(p['group_id'])} • ${p['payment_mode']}',
                                          style: const TextStyle(fontSize: 12)),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                              '+₹${(p['amount'] as num).toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green)),
                                          Text(_formatDate(p['paid_at']),
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

  Widget _ledgerStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}