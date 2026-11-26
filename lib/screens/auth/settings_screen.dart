import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String userId;

  const SettingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final canEdit = FirebaseAuth.instance.currentUser?.uid == userId;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'AKUN',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                enabled: canEdit,
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: const Text(
                  'Edit Profil',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Ubah nama dan nomor HP'),
                trailing: const Icon(Icons.chevron_right),
                onTap: canEdit
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(userId: userId),
                          ),
                        )
                    : null,
              ),
            ),
            if (!canEdit)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Sesi tidak sesuai. Silakan login kembali.'),
              ),
          ],
        ),
      ),
    );
  }
}
