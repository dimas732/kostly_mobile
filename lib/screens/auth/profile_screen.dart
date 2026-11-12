import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../owner_registration_screen.dart'; // Pastikan path import ini sesuai dengan struktur project kamu

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User belum login')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profil Saya', style: TextStyle(color: Colors.black, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black54),
            onPressed: () {
              // TODO: Aksi Setting
            },
          ),
        ],
      ),
      // Menggunakan StreamBuilder agar data profil otomatis ter-update jika ada perubahan di Firestore
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data profil tidak ditemukan.'));
          }

          // Ambil data menggunakan UserModel.fromFirestore
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          UserModel user = UserModel.fromFirestore(userData, currentUser.uid);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER PROFIL (Nama & No HP dari model)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue[800],
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name.isNotEmpty ? user.name : 'Tanpa Nama',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  user.phone_number.isNotEmpty ? user.phone_number : 'Belum ada nomor HP',
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. KOTAK STATISTIK AKTIVITAS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, spreadRadius: 1),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(Icons.bookmark_border, '0', 'Disimpan'),
                        Container(height: 30, width: 1, color: Colors.grey[300]),
                        _buildStatItem(Icons.home_work_outlined, '0', 'Kost Disewa'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. BANNER VERIFIKASI PEMILIK KOS (Terhubung ke OwnerRegistrationScreen)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildVerificationBanner(context, user),
                ),
                const SizedBox(height: 20),

                // 4. MENU LAINNYA
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Lainnya',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      // MENU TOMBOL DAFTAR / DASHBOARD PEMILIK KOS
                      _buildMenuItem(
                        Icons.storefront,
                        user.verification_status == 'verified' ? 'Dashboard Pemilik Kos' : 'Daftar Jadi Pemilik Kos',
                            () {
                          // Selalu izinkan akses ke form pendaftaran selama masa development
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OwnerRegistrationScreen(userId: user.uid),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildMenuItem(Icons.help_outline, 'Pusat Bantuan', () {}),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[700], size: 26),
        const SizedBox(height: 4),
        Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildVerificationBanner(BuildContext context, UserModel user) {
    String message = "Ingin menyewakan properti Anda? Daftar jadi Pemilik Kos sekarang!";
    String buttonText = "LENGKAPI DATA KTP";
    Color bannerColor = Colors.blue[50]!;
    Color borderColor = Colors.blue[200]!;

    if (user.verification_status == 'pending') {
      message = "Dokumen verifikasi Anda sedang ditinjau oleh Admin.";
      buttonText = "MENUNGGU REVIEW (BISA DIKLIK)";
    } else if (user.verification_status == 'verified') {
      message = "Akun Anda telah terverifikasi sebagai Pemilik Kos resmi.";
      buttonText = "KELOLA KOS";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user, color: Colors.blue, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              // Tombol tidak lagi dibatasi/didisable (tidak lagi bernilai null saat pending)
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OwnerRegistrationScreen(userId: user.uid),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}