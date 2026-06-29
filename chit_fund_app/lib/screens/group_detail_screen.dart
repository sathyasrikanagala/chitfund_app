import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';
import 'collect_payment_screen.dart';
import '../services/session_manager.dart';

class GroupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  List<Map<String, dynamic>> _groupMembers = [];
  List<Map<String, dynamic>> _allMembers = [];
  double _collected = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _confirmDeleteGroup() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Group?'),
      content: Text(
          'Are you sure you want to delete "${widget.group['name']}"? This will not delete payment history, but the group will be removed.'),
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
    await ApiService.deleteGroup(widget.group['id']);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group deleted'), backgroundColor: Colors.red),
      );
      Navigator.pop(context, true);
    }
  }
}

Future<void> _loadData() async {
  setState(() => _isLoading = true);
  final groupMembers = await ApiService.getGroupMembers(widget.group['id']);
  final payments = await ApiService.getPayments(groupId: widget.group['id']);

  final collected = payments.fold(0.0, (sum, p) => sum + (p['amount'] as num));

  setState(() {
    _groupMembers = groupMembers;
    _allMembers = groupMembers; // members are now scoped to this group
    _collected = collected;
    _isLoading = false;
  });
}
Future<void> _showAddMemberDialog() async {
  final allMembers = await ApiService.getMembers();
  final existingIds = _groupMembers.map((m) => m['id']).toSet();
  final available =
      allMembers.where((m) => !existingIds.contains(m['id'])).toList();

  if (!mounted) return;

  final action = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_search, color: Color(0xFF1565C0)),
            title: const Text('Add Existing Member'),
            subtitle: const Text('Pick from members not yet in this group'),
            onTap: () => Navigator.pop(ctx, 'existing'),
          ),
          ListTile(
            leading: const Icon(Icons.person_add, color: Color(0xFF1565C0)),
            title: const Text('Add New Member'),
            subtitle: const Text('Create a brand new member record'),
            onTap: () => Navigator.pop(ctx, 'new'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (action == 'existing') {
    await _pickExistingMember(available);
  } else if (action == 'new') {
    await _createAndAddNewMember();
  }
}

Future<void> _pickExistingMember(List<Map<String, dynamic>> available) async {
  if (available.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All members are already in this group, or no members exist yet.')),
      );
    }
    return;
  }

  final selected = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Member',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: available.length,
              itemBuilder: (context, index) {
                final m = available[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1565C0),
                    child: Text(m['name'][0],
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(m['name']),
                  subtitle: Text(m['village'] ?? ''),
                  onTap: () => Navigator.pop(ctx, m),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  if (selected != null) {
    try {
      await ApiService.directAddMemberToGroup(selected['id'], widget.group['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selected['name']} added to group!'),
              backgroundColor: Colors.green),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

Future<void> _createAndAddNewMember() async {
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final villageController = TextEditingController();

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Member',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: villageController,
              decoration: const InputDecoration(
                labelText: 'Village',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (nameController.text.trim().isEmpty ||
                      mobileController.text.trim().isEmpty ||
                      villageController.text.trim().isEmpty) {
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Add to Group'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (confirmed == true) {
    try {
      final newMember = await ApiService.createMember({
        'name': nameController.text.trim(),
        'mobile': mobileController.text.trim(),
        'village': villageController.text.trim(),
        'status': 'Active',
      });
      await ApiService.directAddMemberToGroup(newMember['id'], widget.group['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New member created and added to group!'),
              backgroundColor: Colors.green),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final name = widget.group['name']?.toString() ?? 'Unnamed Group';
    final status = widget.group['status']?.toString() ?? 'Active';
    final amount = (widget.group['amount'] is num)
        ? (widget.group['amount'] as num).toStringAsFixed(0)
        : '0';
    final totalMembers = widget.group['total_members']?.toString() ?? '0';
    final frequency = widget.group['frequency']?.toString() ?? 'Monthly';
    final progress = (widget.group['amount'] as num) * int.parse(totalMembers) > 0
        ? (_collected / ((widget.group['amount'] as num) * int.parse(totalMembers)))
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
  backgroundColor: const Color(0xFF1565C0),
  title: Text(name, style: const TextStyle(color: Colors.white)),
  iconTheme: const IconThemeData(color: Colors.white),
  actions: [
  IconButton(
    icon: const Icon(Icons.refresh, color: Colors.white),
    onPressed: _loadData,
  ),
  if (SessionManager.instance.canDeleteRecords)
    IconButton(
      icon: const Icon(Icons.delete, color: Colors.white),
      onPressed: _confirmDeleteGroup,
    ),
],
),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: status == 'Active' ? Colors.green : Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(status,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem('Installment', '₹$amount', Colors.amberAccent),
                            _statItem('Members',
                                '${_groupMembers.length}/$totalMembers',
                                Colors.lightBlueAccent),
                            _statItem('Frequency', frequency, Colors.greenAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard('Collection Progress', [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Collected', style: TextStyle(color: Colors.grey)),
                        Text('₹${_collected.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1).toDouble(),
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${(progress * 100).clamp(0, 100).toStringAsFixed(0)}% complete',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _quickAction(Icons.payments, 'Collect', Colors.green,
                          () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const CollectPaymentScreen()))),
                      const SizedBox(width: 12),
                      _quickAction(Icons.person_add, 'Add Member',
                          Colors.blue, _showAddMemberDialog),
                      const SizedBox(width: 12),
                      _quickAction(Icons.download, 'Export', Colors.teal, () {}),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionCard('Members (${_groupMembers.length})', [
                    if (_groupMembers.isEmpty)
                      const Text('No members added to this group yet.',
                          style: TextStyle(color: Colors.grey))
                    else
                      ..._groupMembers.map((m) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF1565C0),
                                  child: Text(m['name'][0],
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(m['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                ),
                                Text(m['village'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          )),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
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

  Widget _quickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
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
}