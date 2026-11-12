import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// Import halaman form pendaftaran owner dan dashboard pemilik kos kamu di sini
import '../owner_registration_screen.dart';
import '../admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId; // ID User yang sedang login

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[550], // Sesuai dengan warna latar belakang gambar referensi
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {
              // Aksi ke halaman pengaturan/setting
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          // Tampilkan loading jika data user belum siap
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data profil tidak ditemukan.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String name = userData['fullName'] ?? userData['name'] ?? 'Pengguna KostLy';
          String phone = userData['phoneNumber'] ?? userData['phone'] ?? '-';
          String email = userData['email'] ?? '-';

          // Ambil status verifikasi (default 'none' jika field belum ada)
          String verificationStatus = userData['verificationStatus'] ?? 'none';

          return SingleChildScrollView(
            child: Column(
              children: [
                // BAGIAN 1: HEADER PROFIL (FOTO & INFO USER)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFF2B8EFF),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(phone, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // BAGIAN 2: STATISTIK / MENU UTAMA (Simpan & Kost Disewa)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(Icons.bookmark_border, '0', 'Disimpan'),
                      Container(height: 30, width: 1, color: Colors.grey.shade200),
                      _buildStatItem(Icons.home_outlined, '0', 'Kost Disewa'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // BAGIAN 3: BANNER 4 STATE VERIFIKASI OWNER (DINAMIS)
                _buildVerificationBanner(context, verificationStatus),

                const SizedBox(height: 12),

                // BAGIAN 4: MENU LAINNYA
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lainnya',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),

                      // Menu Daftar Jadi Pemilik Kos (Hanya muncul jika belum pernah daftar atau status none/rejected)
                      if (verificationStatus == 'none' || verificationStatus == 'rejected')
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF3FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.storefront_outlined, color: Color(0xFF2B8EFF)),
                          ),
                          title: const Text('Daftar Jadi Pemilik Kos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            // Navigasi ke halaman form pendaftaran owner
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OwnerRegistrationScreen(userId: widget.userId),
                              ),
                            );
                          },
                        ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF3FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.help_outline_rounded, color: Color(0xFF2B8EFF)),
                        ),
                        title: const Text('Pusat Bantuan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          // Aksi ke pusat bantuan
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget pendukung untuk item statistik
  Widget _buildStatItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2B8EFF)),
        const SizedBox(height: 6),
        Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // =========================================================================
  // LOGIKA 4 STATE BANNER VERIFIKASI PEMILIK KOS
  // =========================================================================
  Widget _buildVerificationBanner(BuildContext context, String status) {

    // STATE 1: Belum pernah mengisi form (Banner tidak dimunculkan)
    if (status == 'none') {
      return const SizedBox.shrink();
    }

    // STATE 2: Sedang ditinjau oleh Admin (PENDING)
    if (status == 'pending') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEBF3FE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2B8EFF).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.verified_user_outlined, color: Color(0xFF2B8EFF), size: 28),
            const SizedBox(height: 8),
            const Text(
              'Dokumen verifikasi Anda sedang ditinjau oleh Admin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pengajuan Anda sedang diproses oleh admin.')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2B8EFF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'MENUNGGU REVIEW (BISA DIKLIK)',
                  style: TextStyle(color: Color(0xFF2B8EFF), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // STATE 3: Akun sudah di-APPROVE (Disetujui)
    if (status == 'verified') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            const SizedBox(height: 8),
            const Text(
              'Selamat! Akun Anda sudah diverifikasi sebagai Pemilik Kos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  // 🔹 Navigasi ke Halaman Dashboard Utama Pemilik Kos (AdminScreen)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text(
                  'MASUK DASHBOARD PEMILIK KOS',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // STATE 4: Akun DITOLAK (REJECTED)
    if (status == 'rejected') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 28),
            const SizedBox(height: 8),
            const Text(
              'Maaf, pengajuan verifikasi Anda ditolak. Silakan ajukan ulang dengan data yang valid.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Arahkan kembali ke Form Pendaftaran Owner untuk daftar ulang
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerRegistrationScreen(userId: widget.userId)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text(
                  'AJUKAN ULANG PENDAFTARAN',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}