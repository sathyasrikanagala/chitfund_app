import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_helper.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  Future<void> _backupData() async {
    setState(() => _isBackingUp = true);
    try {
      final data = await DatabaseHelper.instance.exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: 'chit_fund_backup_$timestamp.json',
            mimeType: 'application/json',
          ),
        ],
        text: 'Chit Fund Manager Backup',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Backup created successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data?'),
        content: const Text(
            'This will add all members, groups, and payments from the backup file. Existing data with the same IDs will be overwritten. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isRestoring = false);
        return;
      }

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        throw Exception('Could not read file');
      }

      final jsonString = utf8.decode(fileBytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      await DatabaseHelper.instance.importAllData(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data restored successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Backup & Restore',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              icon: Icons.backup,
              iconColor: Colors.blue,
              title: 'Backup Data',
              description:
                  'Export all your members, groups, payments, and settings to a file you can save or share.',
              buttonLabel: 'Create Backup',
              isLoading: _isBackingUp,
              onPressed: _backupData,
              buttonColor: const Color(0xFF1565C0),
            ),
            const SizedBox(height: 16),
            _card(
              icon: Icons.restore,
              iconColor: Colors.orange,
              title: 'Restore Data',
              description:
                  'Import data from a previously exported backup file. Existing records will be merged.',
              buttonLabel: 'Choose Backup File',
              isLoading: _isRestoring,
              onPressed: _restoreData,
              buttonColor: Colors.orange.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonLabel,
    required bool isLoading,
    required VoidCallback onPressed,
    required Color buttonColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Icon(icon, color: iconColor, size: 36),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading ? null : onPressed,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}