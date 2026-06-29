import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class RequestJoinGroupScreen extends StatefulWidget {
  const RequestJoinGroupScreen({super.key});

  @override
  State<RequestJoinGroupScreen> createState() => _RequestJoinGroupScreenState();
}

class _RequestJoinGroupScreenState extends State<RequestJoinGroupScreen> {
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _myRequests = [];
  String? _selectedGroupId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final groups = await ApiService.getGroups();
    final allRequests = await ApiService.getJoinRequests();
    final userId = SessionManager.instance.currentUser?['id'];

    final myRequests =
        allRequests.where((r) => r['user_id'] == userId).toList();

    setState(() {
      _groups = groups;
      _myRequests = myRequests;
      _selectedGroupId = groups.isNotEmpty ? groups.first['id'] : null;
      _isLoading = false;
    });
  }

  bool _hasPendingRequestFor(String groupId) {
    return _myRequests.any(
        (r) => r['group_id'] == groupId && r['status'] == 'pending');
  }

  Future<void> _submitRequest() async {
    if (_selectedGroupId == null) return;

    if (_hasPendingRequestFor(_selectedGroupId!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You already have a pending request for this group')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = SessionManager.instance.currentUser!;
      await ApiService.createJoinRequest({
        'user_id': user['id'],
        'group_id': _selectedGroupId,
        'full_name': user['full_name'],
        'mobile': user['mobile'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join request sent! Waiting for agent approval.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Request to Join a Group',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(
                  child: Text('No chit groups available yet.\nCheck back later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select the chit group you want to join. Your agent will review and approve your request.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ..._groups.map((g) {
                        final isPending = _hasPendingRequestFor(g['id']);
                        final isSelected = _selectedGroupId == g['id'];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF1565C0)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: RadioListTile<String>(
                            value: g['id'],
                            groupValue: _selectedGroupId,
                            onChanged: isPending
                                ? null
                                : (val) =>
                                    setState(() => _selectedGroupId = val),
                            title: Text(g['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '₹${(g['amount'] as num).toStringAsFixed(0)} • ${g['frequency']}'),
                            secondary: isPending
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.orange),
                                    ),
                                    child: const Text('Pending',
                                        style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  )
                                : null,
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isSubmitting ||
                                  (_selectedGroupId != null &&
                                      _hasPendingRequestFor(_selectedGroupId!))
                              ? null
                              : _submitRequest,
                          child: _isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Send Join Request'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
