import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'settings_screen.dart';
import 'request_join_group_screen.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  List<Map<String, dynamic>> _myPayments = [];
  Map<String, dynamic>? _myGroup;
  bool _isLoading = true;
  bool _hasJoinedGroup = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final memberId = SessionManager.instance.memberId;

    if (memberId == null) {
      // Not yet linked to a Member record — hasn't been approved into a group
      setState(() {
        _hasJoinedGroup = false;
        _isLoading = false;
      });
      return;
    }

    final payments = await ApiService.getPayments(memberId: memberId);
    final groups = await ApiService.getGroups();

    Map<String, dynamic>? myGroup;
    if (payments.isNotEmpty) {
      myGroup = groups.firstWhere(
        (g) => g['id'] == payments.first['group_id'],
        orElse: () => {},
      );
    }

    setState(() {
      _myPayments = payments;
      _myGroup = myGroup != null && myGroup.isNotEmpty ? myGroup : null;
      _hasJoinedGroup = true;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid =
        _myPayments.fold(0.0, (sum, p) => sum + (p['amount'] as num));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('My Account', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasJoinedGroup
              ? _buildNoGroupView()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, ${SessionManager.instance.fullName}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Here is your chit fund summary',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 20),

                        if (_myGroup != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(_myGroup!['name'],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _statItem(
                                        'Installment',
                                        '₹${(_myGroup!['amount'] as num).toStringAsFixed(0)}',
                                        Colors.amberAccent),
                                    _statItem('Total Paid',
                                        '₹${totalPaid.toStringAsFixed(0)}',
                                        Colors.greenAccent),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                        const Text('Payment History',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        if (_myPayments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text('No payments recorded yet',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else
                          ..._myPayments.map((p) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE8F5E9),
                                    child: Icon(Icons.check,
                                        color: Colors.green),
                                  ),
                                  title: Text(p['payment_type'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(p['payment_mode'],
                                      style: const TextStyle(fontSize: 12)),
                                  trailing: Text(
                                      '₹${(p['amount'] as num).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green)),
                                ),
                              )),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNoGroupView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "You haven't joined a chit group yet",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Contact your chit fund agent to get added to a group, or send a join request below.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Request to Join a Group'),
              onPressed: () async {
  await Navigator.push(context, MaterialPageRoute(
      builder: (_) => const RequestJoinGroupScreen()));
  _loadData();
},
            ),
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
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}