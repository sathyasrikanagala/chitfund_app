import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class MemberDetailScreen extends StatefulWidget {
  final Map<String, dynamic> member;
  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late Map<String, dynamic> _member;
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _villageController;
  late TextEditingController _addressController;
  late TextEditingController _fatherNameController;
  String _status = 'Active';

  @override
  void initState() {
    super.initState();
    _member = Map<String, dynamic>.from(widget.member);
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _member['name'] ?? '');
    _mobileController = TextEditingController(text: _member['mobile'] ?? '');
    _villageController = TextEditingController(text: _member['village'] ?? '');
    _addressController = TextEditingController(text: _member['address'] ?? '');
    _fatherNameController =
        TextEditingController(text: _member['father_name'] ?? '');
    _status = _member['status'] ?? 'Active';
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final updated = Map<String, dynamic>.from(_member);
      updated['name'] = _nameController.text.trim();
      updated['mobile'] = _mobileController.text.trim();
      updated['village'] = _villageController.text.trim();
      updated['address'] = _addressController.text.trim();
      updated['father_name'] = _fatherNameController.text.trim();
      updated['status'] = _status;

      await ApiService.updateMember(updated['id'], updated);

      setState(() {
        _member = updated;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Member updated!'), backgroundColor: Colors.green),
        );
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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member?'),
        content: Text(
            'Are you sure you want to delete ${_member['name']}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.deleteMember(_member['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Member deleted'), backgroundColor: Colors.red),
        );
        Navigator.pop(context, true); // true = refresh list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text(_member['name'] ?? '',
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing && SessionManager.instance.canManageMembers)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (SessionManager.instance.canDeleteRecords)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: Text(
                      (_member['name'] ?? '?')[0],
                      style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_member['name'] ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_member['village'] ?? '',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  if (!_isEditing)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _status == 'Active'
                            ? Colors.green
                            : _status == 'Defaulted'
                                ? Colors.red
                                : Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_status,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isEditing) ...[
              _sectionCard('Edit Details', [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fatherNameController,
                  decoration: const InputDecoration(
                      labelText: 'Father / Spouse Name',
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _mobileController,
                  decoration: const InputDecoration(
                      labelText: 'Mobile',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _villageController,
                  decoration: const InputDecoration(
                      labelText: 'Village',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.home),
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag),
                    border: OutlineInputBorder(),
                  ),
                  items: ['Active', 'Defaulted', 'Completed', 'Exited']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _status = val!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _initControllers();
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSaving ? null : _saveChanges,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ]),
            ] else ...[
              _sectionCard('Personal Details', [
                _detailRow(Icons.person, 'Full Name', _member['name'] ?? ''),
                _detailRow(Icons.people, 'Father / Spouse',
                    _member['father_name'] ?? '-'),
                _detailRow(Icons.phone, 'Mobile', _member['mobile'] ?? ''),
                _detailRow(Icons.location_on, 'Village', _member['village'] ?? ''),
                _detailRow(Icons.home, 'Address', _member['address'] ?? '-'),
                _detailRow(Icons.badge, 'ID Proof',
                    _member['id_proof_type'] ?? '-'),
              ]),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0))),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}