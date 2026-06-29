import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class OrganizationDetailsScreen extends StatefulWidget {
  const OrganizationDetailsScreen({super.key});

  @override
  State<OrganizationDetailsScreen> createState() =>
      _OrganizationDetailsScreenState();
}

class _OrganizationDetailsScreenState
    extends State<OrganizationDetailsScreen> {
  final _nameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await DatabaseHelper.instance.getOrganizationDetails();
    if (details != null) {
      _nameController.text = details['name'] ?? '';
      _regNumberController.text = details['registration_number'] ?? '';
      _stateController.text = details['state'] ?? '';
      _districtController.text = details['district'] ?? '';
      _bankNameController.text = details['bank_name'] ?? '';
      _bankAccountController.text = details['bank_account'] ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await DatabaseHelper.instance.saveOrganizationDetails({
        'name': _nameController.text.trim(),
        'registration_number': _regNumberController.text.trim(),
        'state': _stateController.text.trim(),
        'district': _districtController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'bank_account': _bankAccountController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Organization details saved!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
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
        title: const Text('Organization Details',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCard([
                    _field('Business Name', _nameController, Icons.business),
                    _field('Registration Number', _regNumberController,
                        Icons.numbers),
                    _field('State', _stateController, Icons.map),
                    _field('District', _districtController, Icons.location_city),
                  ]),
                  const SizedBox(height: 16),
                  _buildCard([
                    _field('Bank Name', _bankNameController,
                        Icons.account_balance),
                    _field('Bank Account Number', _bankAccountController,
                        Icons.credit_card),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Details'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
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