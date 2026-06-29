import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:uuid/uuid.dart';
import '../services/receipt_generator.dart';
class CollectPaymentScreen extends StatefulWidget {
  const CollectPaymentScreen({super.key});

  @override
  State<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends State<CollectPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _groups = [];
  String? _selectedMemberId;
  String? _selectedGroupId;
  String _paymentType = 'Installment';
  String _paymentMode = 'Cash';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _paymentTypes = [
    'Installment', 'Advance', 'Penalty', 'Interest', 'Partial Payment'
  ];
  final List<String> _paymentModes = ['Cash', 'UPI', 'Bank Transfer', 'Cheque'];

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
    _selectedMemberId = members.isNotEmpty ? members.first['id'] : null;
    _selectedGroupId = groups.isNotEmpty ? groups.first['id'] : null;
    _isLoading = false;
  });
}

  Future<void> _collectPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberId == null || _selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select member and group')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payment = {
        'id': const Uuid().v4(),
        'member_id': _selectedMemberId,
        'group_id': _selectedGroupId,
        'amount': double.tryParse(_amountController.text.trim()) ?? 0,
        'payment_type': _paymentType,
        'payment_mode': _paymentMode,
        'installment_number': 1,
        'notes': _notesController.text.trim(),
        'paid_at': DateTime.now().toIso8601String(),
      };

      await ApiService.createPayment(payment);

final member = _members.firstWhere((m) => m['id'] == _selectedMemberId);
final group = _groups.firstWhere((g) => g['id'] == _selectedGroupId);

await ApiService.createCashEntry({
  'id': const Uuid().v4(),
  'type': 'in',
  'name': member['name'],
  'description': '$_paymentType - ${group['name']}',
  'amount': payment['amount'],
  'payment_mode': _paymentMode,
  'reference_id': payment['id'],
});
     if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Payment collected!'),
      backgroundColor: Colors.green,
    ),
  );

  await ReceiptGenerator.generateAndShare(
    receiptNo: payment['id'].toString().substring(0, 8).toUpperCase(),
    memberName: member['name'],
    groupName: group['name'],
    amount: payment['amount'] as double,
    paymentType: _paymentType,
    paymentMode: _paymentMode,
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
        title: const Text('Collect Payment',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_members.isEmpty || _groups.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _members.isEmpty
                            ? 'No members found.\nAdd a member first.'
                            : 'No groups found.\nCreate a group first.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Select Member & Group'),
                        _buildCard([
                          DropdownButtonFormField<String>(
                            value: _selectedMemberId,
                            decoration: const InputDecoration(
                              labelText: 'Member',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            items: _members
                                .map((m) => DropdownMenuItem(
                                    value: m['id'] as String,
                                    child: Text(m['name'])))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedMemberId = val),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedGroupId,
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
                            onChanged: (val) {
                              setState(() {
                                _selectedGroupId = val;
                                final group = _groups
                                    .firstWhere((g) => g['id'] == val);
                                _amountController.text =
                                    (group['amount'] as num).toStringAsFixed(0);
                              });
                            },
                          ),
                        ]),

                        _sectionTitle('Payment Details'),
                        _buildCard([
                          DropdownButtonFormField<String>(
                            value: _paymentType,
                            decoration: const InputDecoration(
                              labelText: 'Payment Type',
                              prefixIcon: Icon(Icons.category),
                              border: OutlineInputBorder(),
                            ),
                            items: _paymentTypes
                                .map((t) => DropdownMenuItem(
                                    value: t, child: Text(t)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _paymentType = val!),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Amount (₹)',
                              prefixIcon: Icon(Icons.currency_rupee),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Amount is required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _paymentMode,
                            decoration: const InputDecoration(
                              labelText: 'Payment Mode',
                              prefixIcon: Icon(Icons.payment),
                              border: OutlineInputBorder(),
                            ),
                            items: _paymentModes
                                .map((m) => DropdownMenuItem(
                                    value: m, child: Text(m)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _paymentMode = val!),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              prefixIcon: Icon(Icons.note),
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
                              backgroundColor: Colors.green,
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
                                : const Icon(Icons.check_circle),
                            label: Text(
                                _isSaving
                                    ? 'Saving...'
                                    : 'Collect & Generate Receipt',
                                style: const TextStyle(fontSize: 16)),
                            onPressed: _isSaving ? null : _collectPayment,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
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
      child: Column(
        children: children
            .map((child) => Padding(
                padding: const EdgeInsets.only(bottom: 12), child: child))
            .toList(),
      ),
    );
  }
}