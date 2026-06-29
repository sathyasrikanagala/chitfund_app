import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../services/api_service.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _villageController = TextEditingController();
  final _addressController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _nomineeController = TextEditingController();
  final _nomineeMobileController = TextEditingController();
  final _idNumberController = TextEditingController();
  String _selectedIdProof = 'Aadhaar';
  bool _isSaving = false;

  final List<String> _idProofTypes = [
    'Aadhaar', 'PAN Card', 'Voter ID', 'Driving License'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _villageController.dispose();
    _addressController.dispose();
    _fatherNameController.dispose();
    _nomineeController.dispose();
    _nomineeMobileController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final member = Member(
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        fatherName: _fatherNameController.text.trim(),
        village: _villageController.text.trim(),
        address: _addressController.text.trim(),
        idProofType: _selectedIdProof,
        idProofNumber: _idNumberController.text.trim(),
        nomineeName: _nomineeController.text.trim(),
        nomineeMobile: _nomineeMobileController.text.trim(),
      );

      await ApiService.createMember(member.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true = refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving member: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Add New Member',
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
              _sectionTitle('Personal Details'),
              _buildCard([
                _buildField('Full Name', _nameController,
                    icon: Icons.person, required: true),
                _buildField('Father / Spouse Name', _fatherNameController,
                    icon: Icons.people),
                _buildField('Mobile Number', _mobileController,
                    icon: Icons.phone, required: true,
                    keyboardType: TextInputType.phone),
              ]),

              _sectionTitle('Address'),
              _buildCard([
                _buildField('Village / Town', _villageController,
                    icon: Icons.location_on, required: true),
                _buildField('Full Address', _addressController,
                    icon: Icons.home, maxLines: 3),
              ]),

              _sectionTitle('ID Proof'),
              _buildCard([
                DropdownButtonFormField<String>(
                  value: _selectedIdProof,
                  decoration: const InputDecoration(
                    labelText: 'ID Proof Type',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  items: _idProofTypes.map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedIdProof = val!),
                ),
                const SizedBox(height: 12),
                _buildField('ID Proof Number', _idNumberController,
                    icon: Icons.numbers),
              ]),

              _sectionTitle('Nominee Details'),
              _buildCard([
                _buildField('Nominee Name', _nomineeController,
                    icon: Icons.person_outline),
                _buildField('Nominee Mobile', _nomineeMobileController,
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveMember,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Member',
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
          BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: child,
        )).toList(),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {IconData? icon, bool required = false,
       TextInputType? keyboardType, int maxLines = 1}) {
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
          ? (val) =>
              val == null || val.isEmpty ? '$label is required' : null
          : null,
    );
  }
}