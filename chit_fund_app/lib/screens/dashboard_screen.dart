import 'package:flutter/material.dart';
import 'members_screen.dart';
import 'groups_screen.dart';
import 'reports_screen.dart';
import 'prize_entry_screen.dart';
import 'settings_screen.dart';
import 'cashbook_screen.dart';
import 'collect_payment_screen.dart';
import 'add_member_screen.dart';
import 'create_group_screen.dart';
import 'manage_staff_screen.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const MembersTab(),
    const GroupsTab(),
    const ReportsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Members'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_work), label: 'Groups'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  double _todayCollection = 0;
  double _todayPayout = 0;
  double _cashInHand = 0;
  int _defaultersCount = 0;
  int _activeGroupsCount = 0;
  int _pendingApprovals = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final allPayments = await ApiService.getPayments();
    final allCashEntries = await ApiService.getCashEntries();
    final groups = await ApiService.getGroups();
    final members = await ApiService.getMembers();

    // Pending approvals badge — owner only
    // Pending join requests badge — agent only
int pendingCount = 0;
if (SessionManager.instance.isAgent) {
  final pending = await ApiService.getJoinRequests(status: 'pending');
  pendingCount = pending.length;
}

    final today = DateTime.now();
    bool isToday(String isoDate) {
      final d = DateTime.parse(isoDate);
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }

    final todayPayments =
        allPayments.where((p) => isToday(p['paid_at'])).toList();
    final todayCashEntries =
        allCashEntries.where((e) => isToday(e['entry_date'])).toList();

    final todayCollection =
        todayPayments.fold(0.0, (sum, p) => sum + (p['amount'] as num));
    final todayPayout = todayCashEntries
        .where((e) => e['type'] == 'out')
        .fold(0.0, (sum, e) => sum + (e['amount'] as num));
    final totalIn = allCashEntries
        .where((e) => e['type'] == 'in')
        .fold(0.0, (sum, e) => sum + (e['amount'] as num));
    final totalOut = allCashEntries
        .where((e) => e['type'] == 'out')
        .fold(0.0, (sum, e) => sum + (e['amount'] as num));

    setState(() {
      _todayCollection = todayCollection;
      _todayPayout = todayPayout;
      _cashInHand = totalIn - totalOut;
      _defaultersCount =
          members.where((m) => m['status'] == 'Defaulted').length;
      _activeGroupsCount =
          groups.where((g) => g['status'] == 'Active').length;
      _pendingApprovals = pendingCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionManager.instance;
    final greeting = _greeting();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          // Pending approval bell — owner only
          if (session.isAgent && _pendingApprovals > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ManageStaffScreen()),
                  ).then((_) => _loadDashboardData()),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_pendingApprovals',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
          if (session.canAccessSettings)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("Here's today's summary",
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),

                    // Stats
                    Row(children: [
                      _StatCard(
                          title: 'Today Collection',
                          value: '₹${_todayCollection.toStringAsFixed(0)}',
                          icon: Icons.arrow_downward,
                          color: Colors.green),
                      const SizedBox(width: 12),
                      _StatCard(
                          title: 'Today Payout',
                          value: '₹${_todayPayout.toStringAsFixed(0)}',
                          icon: Icons.arrow_upward,
                          color: Colors.red),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _StatCard(
                          title: 'Cash in Hand',
                          value: '₹${_cashInHand.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet,
                          color: Colors.blue),
                      const SizedBox(width: 12),
                      _StatCard(
                          title: 'Active Groups',
                          value: '$_activeGroupsCount',
                          icon: Icons.group,
                          color: Colors.purple),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _StatCard(
                          title: 'Defaulters',
                          value: '$_defaultersCount',
                          icon: Icons.person_off,
                          color: Colors.orange),
                      if (session.isAgent) ...[
                        const SizedBox(width: 12),
                        _StatCard(
                            title: 'Pending Approvals',
                            value: '$_pendingApprovals',
                            icon: Icons.pending_actions,
                            color: Colors.red),
                      ] else
                        const Expanded(child: SizedBox()),
                    ]),

                    const SizedBox(height: 24),
                    const Text('Quick Actions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        if (session.canCollectPayments)
                          _ActionButton(
                              label: 'Collect Payment',
                              icon: Icons.payments,
                              color: Colors.green,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const CollectPaymentScreen()))),
                        if (session.canManageMembers)
                          _ActionButton(
                              label: 'Add Member',
                              icon: Icons.person_add,
                              color: Colors.blue,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AddMemberScreen()))),
                        if (session.canManageGroups)
                          _ActionButton(
                              label: 'New Group',
                              icon: Icons.group_add,
                              color: Colors.purple,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const CreateGroupScreen()))),
                        if (session.canRecordPrizes)
                          _ActionButton(
                              label: 'Prize Entry',
                              icon: Icons.emoji_events,
                              color: Colors.orange,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PrizeEntryScreen()))),
                        if (session.isAgent)
                          _ActionButton(
                              label: 'Manage Users',
                              icon: Icons.manage_accounts,
                              color: Colors.teal,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ManageStaffScreen())).then(
                                  (_) => _loadDashboardData())),
                        _ActionButton(
                            label: 'Reports',
                            icon: Icons.bar_chart,
                            color: Colors.teal,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ReportsScreen()))),
                        _ActionButton(
                            label: 'Cashbook',
                            icon: Icons.book,
                            color: Colors.brown,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CashbookScreen()))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final name = SessionManager.instance.fullName.split(' ').first;
    final timeGreeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    return '$timeGreeting, $name';
  }
}

// ── Tab shells ────────────────────────────────────────────
class MembersTab extends StatelessWidget {
  const MembersTab({super.key});
  @override
  Widget build(BuildContext context) => const MembersScreen();
}

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});
  @override
  Widget build(BuildContext context) => const GroupsScreen();
}

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});
  @override
  Widget build(BuildContext context) => const ReportsScreen();
}

// ── Reusable widgets ──────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}