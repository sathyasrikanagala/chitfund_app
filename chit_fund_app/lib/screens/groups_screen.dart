import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'collect_payment_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    final groups = await ApiService.getGroups();
    setState(() {
      _groups = groups;
      _isLoading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active': return Colors.green;
      case 'Completed': return Colors.blue;
      case 'Closed': return Colors.grey;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Chit Groups', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadGroups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_work_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No chit groups yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const CreateGroupScreen()));
                          if (result == true) _loadGroups();
                        },
                        child: const Text('Create First Group'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGroups,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(group['name'],
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(group['status'])
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: _statusColor(group['status'])),
                                    ),
                                    child: Text(group['status'],
                                        style: TextStyle(
                                            color: _statusColor(group['status']),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _infoChip(Icons.currency_rupee,
                                      'Installment: ₹${group['amount'].toStringAsFixed(0)}'),
                                  const SizedBox(width: 12),
                                  _infoChip(Icons.people,
                                      '${group['total_members']} members'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _infoChip(
                                      Icons.calendar_today, group['frequency']),
                                  const SizedBox(width: 12),
                                  _infoChip(Icons.emoji_events,
                                      group['draw_method'] ?? 'Auction'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.visibility, size: 16),
                                      label: const Text('View Details'),
                                      onPressed: () async {
  final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)));
  if (result == true) _loadGroups();
},
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1565C0),
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.payments, size: 16),
                                      label: const Text('Collect'),
                                      onPressed: () {
                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const CollectPaymentScreen()));
                                      },
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
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Group', style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final result = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
          if (result == true) _loadGroups();
        },
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}