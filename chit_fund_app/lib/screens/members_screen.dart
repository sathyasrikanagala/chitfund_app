import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_member_screen.dart';
import 'member_detail_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';
  String _selectedVillage = 'All';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
  setState(() => _isLoading = true);
  try {
    final members = await ApiService.getMembers();
    setState(() {
      _members = members;
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading members: $e')),
      );
    }
  }
}

  List<Map<String, dynamic>> get _filtered {
    return _members.where((m) {
      final matchesSearch = _searchController.text.isEmpty ||
          m['name'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
          m['mobile'].contains(_searchController.text) ||
          m['village'].toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesStatus = _selectedStatus == 'All' || m['status'] == _selectedStatus;
      final matchesVillage = _selectedVillage == 'All' || m['village'] == _selectedVillage;
      return matchesSearch && matchesStatus && matchesVillage;
    }).toList();
  }

  List<String> get _villages {
    final villages = _members.map((m) => m['village'] as String).toSet().toList();
    villages.sort();
    return ['All', ...villages];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active': return Colors.green;
      case 'Defaulted': return Colors.red;
      case 'Completed': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _showFilter() {
    String tempStatus = _selectedStatus;
    String tempVillage = _selectedVillage;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Members',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => setModalState(() {
                      tempStatus = 'All';
                      tempVillage = 'All';
                    }),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('By Status',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', 'Active', 'Defaulted', 'Completed']
                    .map((s) => FilterChip(
                          label: Text(s),
                          selected: tempStatus == s,
                          onSelected: (_) => setModalState(() => tempStatus = s),
                          selectedColor: const Color(0xFF1565C0).withOpacity(0.2),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text('By Village',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _villages
                    .map((v) => FilterChip(
                          label: Text(v),
                          selected: tempVillage == v,
                          onSelected: (_) => setModalState(() => tempVillage = v),
                          selectedColor: const Color(0xFF1565C0).withOpacity(0.2),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedStatus = tempStatus;
                      _selectedVillage = tempVillage;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filter'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterTag(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0))),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF1565C0)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Members', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMembers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name, mobile, village...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Active filter tags
          if (_selectedStatus != 'All' || _selectedVillage != 'All')
            Container(
              color: Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  if (_selectedStatus != 'All')
                    _filterTag(_selectedStatus,
                        () => setState(() => _selectedStatus = 'All')),
                  if (_selectedVillage != 'All')
                    _filterTag(_selectedVillage,
                        () => setState(() => _selectedVillage = 'All')),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedStatus = 'All';
                      _selectedVillage = 'All';
                    }),
                    child: const Text('Clear all',
                        style: TextStyle(color: Colors.blue, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Count + filter button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${filtered.length} members found',
                    style: const TextStyle(color: Colors.grey)),
                TextButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                  onPressed: _showFilter,
                ),
              ],
            ),
          ),

          // Members list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No members yet',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 16)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AddMemberScreen()));
                                if (result == true) _loadMembers();
                              },
                              child: const Text('Add First Member'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMembers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final member = filtered[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF1565C0),
                                  child: Text(
                                    member['name'][0],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(member['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Icons.phone,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(member['mobile'],
                                          style: const TextStyle(fontSize: 13)),
                                    ]),
                                    Row(children: [
                                      const Icon(Icons.location_on,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(member['village'],
                                          style: const TextStyle(fontSize: 13)),
                                    ]),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(member['status'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: _statusColor(member['status'])),
                                  ),
                                  child: Text(
                                    member['status'],
                                    style: TextStyle(
                                        color: _statusColor(member['status']),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                onTap: () async {
  final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => MemberDetailScreen(member: member)));
  if (result == true) _loadMembers();
},
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Member',
            style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final result = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddMemberScreen()));
          if (result == true) _loadMembers();
        },
      ),
    );
  }
}