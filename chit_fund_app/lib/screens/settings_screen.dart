import 'package:flutter/material.dart';
import 'organization_details_screen.dart';
import '../services/session_manager.dart';
import 'login_screen.dart';
import 'manage_staff_screen.dart';
import 'backup_restore_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(SessionManager.instance.fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(
                        SessionManager.instance.isAgent ? 'Agent' : 'Member',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (SessionManager.instance.isAgent) ...[
            _sectionTitle('Organization'),
            _settingsTile(
              Icons.business,
              'Organization Details',
              'Name, registration, state',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const OrganizationDetailsScreen())),
            ),
            _settingsTile(Icons.people, 'Manage Members',
                'Approve join requests, view members',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const ManageStaffScreen()))),
            _sectionTitle('Data'),
            _settingsTile(Icons.backup, 'Backup & Restore',
                'Export or import your data',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const BackupRestoreScreen()))),
          ],

         _sectionTitle('Account'),
_settingsTile(Icons.person, 'Edit My Profile', 'Name and mobile number',
    onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => const EditProfileScreen()))),

_sectionTitle('Security'),
_settingsTile(Icons.lock, 'Change Password', '',
    onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => const ChangePasswordScreen()))),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: () {
              SessionManager.instance.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1)),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle,
      {required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1565C0)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}