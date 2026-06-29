import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ManageStaffScreen extends StatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _approvedRequests = [];
  Map<String, dynamic> _groupsById = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allRequests = await ApiService.getJoinRequests();
    final groups = await ApiService.getGroups();

    setState(() {
      _pendingRequests =
          allRequests.where((r) => r['status'] == 'pending').toList();
      _approvedRequests =
          allRequests.where((r) => r['status'] == 'approved').toList();
      _groupsById = {for (var g in groups) g['id']: g};
      _isLoading = false;
    });
  }

  Future<void> _updateApproval(String requestId, String status) async {
    try {
      await ApiService.updateJoinRequestApproval(requestId, status);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'approved'
              ? 'Join request approved — member added!'
              : 'Join request rejected'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _groupName(String groupId) {
    return _groupsById[groupId]?['name'] ?? 'Unknown group';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Join Requests', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_pendingRequests.length}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Approved'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingList(),
                _buildApprovedList(),
              ],
            ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No pending join requests',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final req = _pendingRequests[index];
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
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF1565C0),
                        child: Text(
                          (req['full_name'] as String)[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(req['full_name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            if (req['mobile'] != null && req['mobile'] != '')
                              Text(req['mobile'],
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('Wants to join: ${_groupName(req['group_id'])}',
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF1565C0))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          onPressed: () =>
                              _updateApproval(req['id'], 'rejected'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          onPressed: () =>
                              _updateApproval(req['id'], 'approved'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApprovedList() {
    if (_approvedRequests.isEmpty) {
      return const Center(
        child: Text('No approved members yet',
            style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _approvedRequests.length,
        itemBuilder: (context, index) {
          final req = _approvedRequests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(
                  (req['full_name'] as String)[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(req['full_name'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Joined: ${_groupName(req['group_id'])}',
                  style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}