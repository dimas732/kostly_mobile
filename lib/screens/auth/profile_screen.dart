import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/kos_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../owner_registration_screen.dart';
import '../admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId; // ID User yang sedang login

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _blue = Color(0xFF2B8EFF);
  static const Color _softBlue = Color(0xFFEBF3FE);

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data profil tidak ditemukan.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String name = userData['fullName'] ?? userData['name'] ?? 'Pengguna KostLy';
          final String phone = userData['phoneNumber'] ?? userData['phone'] ?? '-';
          final String email = userData['email'] ?? '-';
          final String verificationStatus = userData['verificationStatus'] ?? 'none';
          final String role =
          (userData['roles'] ?? userData['role'] ?? '').toString().toLowerCase().trim();
          final int favoriteCount = (userData['favorites'] as List?)?.length ?? 0;

          // Pemilik = role 'owner' (sama seperti AuthGate) atau sudah terverifikasi
          final bool isOwner = role == 'owner' || verificationStatus == 'verified';

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(name, phone, email, isOwner),
                const SizedBox(height: 12),
                if (isOwner)
                  ..._buildOwnerSections(context)
                else
                  ..._buildSeekerSections(context, favoriteCount, verificationStatus),
                const SizedBox(height: 12),
                _buildLogoutButton(),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // HEADER (dipakai bersama, ada badge "Pemilik Kos" khusus owner)
  // =========================================================================
  Widget _buildHeader(String name, String phone, String email, bool isOwner) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: isOwner ? Colors.green : _blue,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isOwner ? Colors.green : _blue).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOwner ? Icons.storefront_outlined : Icons.search,
                        size: 13,
                        color: isOwner ? Colors.green[700] : _blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOwner ? 'Pemilik Kos' : 'Pencari Kos',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOwner ? Colors.green[700] : _blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
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
                    Flexible(
                      child: Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PROFIL PEMILIK KOS
  // =========================================================================
  List<Widget> _buildOwnerSections(BuildContext context) {
    return [
      // Ringkasan Total / Penuh / Tersedia
      StreamBuilder<List<KosModel>>(
        stream: _firestoreService.getDaftarKosByOwner(),
        builder: (context, snap) {
          final list = snap.data ?? [];
          final total = list.length;
          final penuh = list.where((k) => k.kamarTersedia <= 0).length;
          final tersedia = total - penuh;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(Icons.home_outlined, '$total', 'Total', _blue),
                Container(height: 30, width: 1, color: Colors.grey.shade200),
                _buildStatItem(Icons.block, '$penuh', 'Penuh', Colors.red),
                Container(height: 30, width: 1, color: Colors.grey.shade200),
                _buildStatItem(Icons.check_circle_outline, '$tersedia', 'Tersedia', Colors.green),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      _buildMenuCard('Kelola Properti', [
        _buildMenuTile(
          icon: Icons.dashboard_outlined,
          title: 'Dashboard Pemilik Kos',
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AdminScreen()),
                  (route) => false,
            );
          },
        ),
        _buildMenuTile(icon: Icons.help_outline_rounded, title: 'Pusat Bantuan', onTap: () {}),
      ]),
    ];
  }

  // =========================================================================
  // PROFIL PENCARI KOS
  // =========================================================================
  List<Widget> _buildSeekerSections(BuildContext context, int favoriteCount, String status) {
    return [
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
            _buildStatItem(Icons.bookmark_border, '$favoriteCount', 'Disimpan', _blue),
            Container(height: 30, width: 1, color: Colors.grey.shade200),
            _buildStatItem(Icons.home_outlined, '0', 'Kost Disewa', _blue),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Banner status pengajuan jadi pemilik (khusus pencari)
      _buildVerificationBanner(context, status),
      const SizedBox(height: 12),

      _buildMenuCard('Lainnya', [
        if (status == 'none' || status == 'rejected')
          _buildMenuTile(
            icon: Icons.storefront_outlined,
            title: 'Daftar Jadi Pemilik Kos',
            onTap: () => _openOwnerRegistration(context),
          ),
        _buildMenuTile(icon: Icons.help_outline_rounded, title: 'Pusat Bantuan', onTap: () {}),
      ]),
    ];
  }

  void _openOwnerRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerRegistrationScreen(userId: widget.userId),
      ),
    );
  }

  // =========================================================================
  // WIDGET PENDUKUNG
  // =========================================================================
  Widget _buildStatItem(IconData icon, String count, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 6),
        Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuCard(String title, List<Widget> children) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _softBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _blue),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () async {
            // Tutup profil dulu supaya AuthGate di bawahnya bisa mengambil alih
            Navigator.of(context).popUntil((route) => route.isFirst);
            await AuthService().signOut();
          },
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          label: const Text(
            'Keluar',
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.redAccent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // BANNER STATUS VERIFIKASI (hanya untuk pencari kos)
  // =========================================================================
  Widget _buildVerificationBanner(BuildContext context, String status) {
    if (status == 'pending') {
      return _buildBanner(
        color: _blue,
        bg: _softBlue,
        icon: Icons.verified_user_outlined,
        message: 'Dokumen verifikasi Anda sedang ditinjau oleh Admin.',
        buttonLabel: 'MENUNGGU REVIEW',
        outlined: true,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengajuan Anda sedang diproses oleh admin.')),
          );
        },
      );
    }

    if (status == 'rejected') {
      return _buildBanner(
        color: Colors.redAccent,
        bg: Colors.red.shade50,
        icon: Icons.cancel_outlined,
        message: 'Maaf, pengajuan verifikasi Anda ditolak. Silakan ajukan ulang dengan data yang valid.',
        buttonLabel: 'AJUKAN ULANG PENDAFTARAN',
        onPressed: () => _openOwnerRegistration(context),
      );
    }

    // 'none' -> tidak ada banner. 'verified' ditangani sebagai profil pemilik.
    return const SizedBox.shrink();
  }

  Widget _buildBanner({
    required Color color,
    required Color bg,
    required IconData icon,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: outlined
                ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(buttonLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            )
                : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(buttonLabel,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
