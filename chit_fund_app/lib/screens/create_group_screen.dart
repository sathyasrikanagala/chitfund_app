import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/api_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _frequency = 'Monthly';
  String _drawMethod = 'Auction';
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _membersController = TextEditingController();
  final _commissionController = TextEditingController();
  final _startDateController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _membersController.dispose();
    _commissionController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final group = ChitGroup(
        name: _nameController.text.trim(),
        amount: double.tryParse(_amountController.text.trim()) ?? 0,
        totalMembers: int.tryParse(_membersController.text.trim()) ?? 0,
        frequency: _frequency,
        drawMethod: _drawMethod,
        commissionPercent:
            double.tryParse(_commissionController.text.trim()) ?? 0,
        startDate: _startDateController.text.trim().isEmpty
            ? DateTime.now().toIso8601String()
            : _startDateController.text.trim(),
      );

      await ApiService.createGroup(group.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chit group created!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
        title: const Text('Create Chit Group',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Group Details'),
              _buildCard([
                _buildField('Group Name / Code', _nameController,
                    icon: Icons.group_work, required: true),
                _buildField('Chit Amount (₹)', _amountController,
                    icon: Icons.currency_rupee, required: true,
                    keyboardType: TextInputType.number),
                _buildField('Number of Members', _membersController,
                    icon: Icons.people, required: true,
                    keyboardType: TextInputType.number),
              ]),

              _sectionTitle('Schedule'),
              _buildCard([
                _buildField('Start Date (e.g. 2026-06-18)',
                    _startDateController,
                    icon: Icons.calendar_today, required: true),
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    prefixIcon: Icon(Icons.repeat),
                    border: OutlineInputBorder(),
                  ),
                  items: ['Weekly', 'Monthly', 'Bi-Monthly']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) => setState(() => _frequency = val!),
                ),
              ]),

              _sectionTitle('Prize & Commission'),
              _buildCard([
                DropdownButtonFormField<String>(
                  initialValue: _drawMethod,
                  decoration: const InputDecoration(
                    labelText: 'Prize Selection Method',
                    prefixIcon: Icon(Icons.emoji_events),
                    border: OutlineInputBorder(),
                  ),
                  items: ['Auction', 'Lottery', 'Fixed Rotation']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) => setState(() => _drawMethod = val!),
                ),
                const SizedBox(height: 12),
                _buildField(
                    'Foreman Commission (%)', _commissionController,
                    icon: Icons.percent,
                    keyboardType: TextInputType.number),
              ]),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSaving ? null : _saveGroup,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Group',
                          style: TextStyle(fontSize: 16)),
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
            .map((child) =>
                Padding(padding: const EdgeInsets.only(bottom: 12), child: child))
            .toList(),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {IconData? icon,
      bool required = false,
      TextInputType? keyboardType,
      int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (val) => val == null || val.isEmpty ? '$label is required' : null
          : null,
    );
  }
}