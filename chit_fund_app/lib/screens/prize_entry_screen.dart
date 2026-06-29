import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';
import '../services/receipt_generator.dart';

class PrizeEntryScreen extends StatefulWidget {
  const PrizeEntryScreen({super.key});

  @override
  State<PrizeEntryScreen> createState() => _PrizeEntryScreenState();
}

class _PrizeEntryScreenState extends State<PrizeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController();
  final _witnessController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _groups = [];
  String? _selectedGroupId;
  String? _selectedWinnerId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final members = await ApiService.getMembers();
    final groups = await ApiService.getGroups();
    setState(() {
      _members = members;
      _groups = groups;
      _selectedGroupId = groups.isNotEmpty ? groups.first['id'] : null;
      _selectedWinnerId = members.isNotEmpty ? members.first['id'] : null;
      _isLoading = false;
    });
  }

  double get _chitValue {
    if (_selectedGroupId == null) return 0;
    final group = _groups.firstWhere((g) => g['id'] == _selectedGroupId);
    return (group['amount'] as num).toDouble() *
        (group['total_members'] as num).toDouble();
  }

  double get _commission {
    if (_selectedGroupId == null) return 0;
    final group = _groups.firstWhere((g) => g['id'] == _selectedGroupId);
    final pct = (group['commission_percent'] as num?)?.toDouble() ?? 0;
    return _chitValue * pct / 100;
  }

  double get _discount => double.tryParse(_discountController.text) ?? 0;

  double get _netPayout => _chitValue - _discount - _commission;

  Future<void> _savePrize() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroupId == null || _selectedWinnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select group and winner')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final group = _groups.firstWhere((g) => g['id'] == _selectedGroupId);
      final winner = _members.firstWhere((m) => m['id'] == _selectedWinnerId);

      final prize = {
        'id': const Uuid().v4(),
        'group_id': _selectedGroupId,
        'member_id': _selectedWinnerId,
        // FIX: derive installment_number from the group's current cycle
        'installment_number': group['current_installment'] ?? 1,
        'chit_value': _chitValue,
        'discount_amount': _discount,
        'commission_amount': _commission,
        'net_payout': _netPayout,
        'draw_method': group['draw_method'],
        'witnesses': _witnessController.text.trim(),
        'notes': _notesController.text.trim(),
        'prize_date': DateTime.now().toIso8601String(),
      };

      await ApiService.createPrize(prize);

      // FIX: single cash entry via ApiService only — removed duplicate DatabaseHelper call
      await ApiService.createCashEntry({
        'id': const Uuid().v4(),
        'type': 'out',
        'name': winner['name'],
        'description': 'Prize Payout - ${group['name']}',
        'amount': _netPayout,
        'payment_mode': 'Cash',
        'reference_id': prize['id'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prize recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        await ReceiptGenerator.generateAndShare(
          receiptNo: prize['id'].toString().substring(0, 8).toUpperCase(),
          memberName: winner['name'],
          groupName: group['name'],
          amount: _netPayout,
          paymentType: 'Prize Payout',
          paymentMode: 'Cash',
          date: DateTime.now(),
          notes: _notesController.text.trim(),
        );

        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Prize / Auction Entry',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_members.isEmpty || _groups.isEmpty)
              ? Center(
                  child: Text(
                    _members.isEmpty
                        ? 'No members found.\nAdd a member first.'
                        : 'No groups found.\nCreate a group first.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Group & Winner'),
                        _buildCard([
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGroupId,
                            decoration: const InputDecoration(
                              labelText: 'Chit Group',
                              prefixIcon: Icon(Icons.group_work),
                              border: OutlineInputBorder(),
                            ),
                            items: _groups
                                .map((g) => DropdownMenuItem(
                                    value: g['id'] as String,
                                    child: Text(g['name'])))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedGroupId = val),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedWinnerId,
                            decoration: const InputDecoration(
                              labelText: 'Prize Winner',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            items: _members
                                .map((m) => DropdownMenuItem(
                                    value: m['id'] as String,
                                    child: Text(m['name'])))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedWinnerId = val),
                          ),
                        ]),

                        _sectionTitle('Prize Calculation'),
                        _buildCard([
                          _readOnlyField('Chit Value',
                              '₹${_chitValue.toStringAsFixed(0)}'),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Discount Amount (₹)',
                              prefixIcon: Icon(Icons.remove_circle_outline),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _readOnlyField('Foreman Commission',
                              '₹${_commission.toStringAsFixed(0)}'),
                          const SizedBox(height: 12),
                          _readOnlyField('Net Prize Amount',
                              '₹${_netPayout.toStringAsFixed(0)}',
                              highlight: true),
                        ]),

                        _sectionTitle('Draw Minutes'),
                        _buildCard([
                          TextFormField(
                            controller: _witnessController,
                            decoration: const InputDecoration(
                              labelText: 'Witnesses Present',
                              prefixIcon: Icon(Icons.people),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Minutes / Notes',
                              prefixIcon: Icon(Icons.notes),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.emoji_events),
                            label: Text(
                                _isSaving
                                    ? 'Saving...'
                                    : 'Record Prize & Release Payout',
                                style: const TextStyle(fontSize: 15)),
                            onPressed: _isSaving ? null : _savePrize,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _readOnlyField(String label, String value,
      {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: highlight ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: highlight ? 16 : 14,
                  color: highlight ? Colors.green.shade700 : Colors.black)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0))),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }
}