import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/kos_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../owner_registration_screen.dart';
import '../admin_screen.dart';
import '../add_edit_kos_screen.dart';
import '../../models/user_model.dart';
import '../../widgets/kos_thumbnail.dart';
import 'settings_screen.dart';
import 'package:kost_ly/screens/help_center_screen.dart';

import 'package:intl/intl.dart';

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

  late final _ownerProperties = _firestoreService.getDaftarKosByOwner();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data profil tidak ditemukan.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final profileName = UserModel.profileName(userData);
          final profilePhone = UserModel.profilePhone(userData);
          final String name =
              profileName.isEmpty ? 'Pengguna KostLy' : profileName;
          final String phone = profilePhone.isEmpty ? '-' : profilePhone;
          final String email = userData['email'] ?? '-';
          final String verificationStatus = UserModel.accountStatus(userData);
          final String role = (userData['roles'] ?? userData['role'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          final int favoriteCount =
              (userData['favorites'] as List?)?.length ?? 0;

          // Pemilik = role 'owner' (sama seperti AuthGate) atau sudah terverifikasi
          final bool isOwner =
              role == 'owner' || verificationStatus == 'verified';

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(name, phone, email, isOwner, verificationStatus),
                const SizedBox(height: 12),
                if (isOwner)
                  ..._buildOwnerSections(context)
                else
                  ..._buildSeekerSections(
                    context,
                    favoriteCount,
                    verificationStatus,
                  ),
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
  Widget _buildHeader(
    String name,
    String phone,
    String email,
    bool isOwner,
    String accountStatus,
  ) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: isOwner ? Colors.green : _blue,
            child: Text(
              name.isNotEmpty ? name.characters.first.toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
                if (isOwner)
                  Text(switch (accountStatus) {
                    'verified' => 'Akun terverifikasi',
                    'pending' => 'Akun menunggu verifikasi',
                    'rejected' => 'Verifikasi akun ditolak',
                    'conflict' => 'Status akun perlu dikonfirmasi admin',
                    _ => 'Verifikasi akun belum tercatat',
                  }),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        phone,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
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
        stream: _ownerProperties,
        builder: (context, snap) {
          if (snap.hasError) {
            return _buildMenuCard('Status Verifikasi Kos', [
              const Text('Status verifikasi gagal dimuat.'),
            ]);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!.toList()
            ..sort(
              (a, b) => (b.verificationUpdatedAt?.millisecondsSinceEpoch ?? 0)
                  .compareTo(
                    a.verificationUpdatedAt?.millisecondsSinceEpoch ?? 0,
                  ),
            );
          final total = list.length;
          final penuh = list.where((k) => k.kamarTersedia <= 0).length;
          final tersedia = total - penuh;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      Icons.home_outlined,
                      '$total',
                      'Total',
                      _blue,
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.shade200,
                    ),
                    _buildStatItem(Icons.block, '$penuh', 'Penuh', Colors.red),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.shade200,
                    ),
                    _buildStatItem(
                      Icons.check_circle_outline,
                      '$tersedia',
                      'Tersedia',
                      Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _verificationSection(list),
            ],
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
        _buildMenuTile(
          icon: Icons.help_outline_rounded,
          title: 'Pusat Bantuan',
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HelpCenterScreen(),
                ),
            );
          },
        ),
      ]),
    ];
  }

  // =========================================================================
  // PROFIL PENCARI KOS
  // =========================================================================
  List<Widget> _buildSeekerSections(
    BuildContext context,
    int favoriteCount,
    String status,
  ) {
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
            _buildStatItem(
              Icons.bookmark_border,
              '$favoriteCount',
              'Disimpan',
              _blue,
            ),
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
        _buildMenuTile(
          icon: Icons.help_outline_rounded,
          title: 'Pusat Bantuan',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HelpCenterScreen(),
              ),
            );
          },
        ),
      ]),
    ];
  }

  Widget _verificationSection(List<KosModel> list) {
    int count(String status) =>
        list.where((k) => k.verificationStatus == status).length;
    final pending = count('pending');
    final results = list.where(
      (k) => ['verified', 'rejected'].contains(k.verificationStatus),
    );
    return _buildMenuCard('Status Verifikasi Kos', [
      if (list.isEmpty)
        const Text(
          'Belum ada pengajuan verifikasi kos. Daftarkan kos Anda untuk memulai proses verifikasi.',
        )
      else ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _softBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${count('verified')} terverifikasi  ·  $pending menunggu  ·  ${count('rejected')} ditolak",
              ),
              if (pending > 0)
                Text(
                  'Anda memiliki $pending kos yang sedang menunggu verifikasi.',
                ),
              if (results.isNotEmpty)
                Text(
                  results.first.verificationStatus == 'verified'
                      ? '${results.first.name} telah terverifikasi.'
                      : 'Pengajuan ${results.first.name} ditolak.',
                ),
            ],
          ),
        ),
        ...list.map(_verificationCard),
      ],
    ]);
  }

  Widget _verificationCard(KosModel kos) {
    final (label, color, icon, info) = switch (kos.verificationStatus) {
      'pending' => (
        'Menunggu Verifikasi',
        Colors.orange.shade900,
        Icons.schedule,
        'Pengajuan kos Anda sedang menunggu pemeriksaan admin.',
      ),
      'verified' => (
        'Terverifikasi',
        Colors.green.shade800,
        Icons.check_circle_outline,
        'Properti kos Anda telah disetujui oleh admin.',
      ),
      'rejected' => (
        'Verifikasi Ditolak',
        Colors.red.shade800,
        Icons.cancel_outlined,
        kos.rejectionReason.trim().isEmpty
            ? 'Admin menolak pengajuan ini. Alasan penolakan belum tersedia.'
            : kos.rejectionReason,
      ),
      _ => (
        'Status Verifikasi Belum Tercatat',
        Colors.grey.shade700,
        Icons.history,
        '',
      ),
    };
    final pending = kos.verificationStatus == 'pending';
    final date = DateFormat('dd/MM/yyyy HH:mm');
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: kosThumbnail(kos.images.firstOrNull ?? ''),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kos.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(kos.address),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Chip(
            avatar: Icon(icon, size: 16, color: color),
            label: Text(label, style: TextStyle(color: color)),
          ),
          if (kos.verificationSubmittedAt case final submitted?)
            Text('Diajukan ${date.format(submitted.toLocal())}'),
          if (kos.verificationUpdatedAt case final updated?)
            Text('Diperbarui ${date.format(updated.toLocal())}'),
          if (info.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(info),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: pending ? 2 / 3 : 1, color: color),
            const Text(
              'Pengajuan → Menunggu Verifikasi → Hasil Verifikasi',
              style: TextStyle(fontSize: 11),
            ),
          ],
          if (pending &&
              ['sending', 'uncertain'].contains(kos.telegramDeliveryStatus))
            const Text('Pengiriman sedang dikonfirmasi oleh admin.'),
          if (pending && kos.telegramDeliveryStatus == 'queued')
            const Text('Pengajuan masuk antrean Telegram.'),
          if (pending &&
              (kos.telegramDeliveryStatus == null ||
                  kos.telegramDeliveryStatus == 'failed') &&
              (kos.telegramSentFor == null ||
                  kos.telegramSentFor != kos.verificationSubmittedAt))
            TextButton(
              onPressed: () async {
                var message = 'Permintaan kirim ulang telah diproses.';
                try {
                  await _firestoreService.retryTelegram(kos.id);
                } catch (_) {
                  message =
                      'Pengiriman belum terkonfirmasi. Silakan coba lagi.';
                }
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(message)));
                }
              },
              child: const Text('Coba kirim ke Telegram'),
            ),
          if (kos.verificationStatus == 'rejected')
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditKosScreen(kost: kos, resubmit: true),
                ),
              ),
              child: const Text('Perbaiki dan Ajukan Ulang'),
            ),
        ],
      ),
    );
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
  Widget _buildStatItem(
    IconData icon,
    String count,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 25,),
        const SizedBox(height: 6),
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
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
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: () async {
            // Tutup profil dulu supaya AuthGate di bawahnya bisa mengambil alih
            Navigator.of(context).popUntil((route) => route.isFirst);
            await AuthService().signOut();
          },
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          label: const Text(
            'Keluar',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE57373), width: 1,),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // BANNER STATUS VERIFIKASI (hanya untuk pencari kos)
  // =========================================================================
  Widget _buildVerificationBanner(BuildContext context, String status) {
    if (status == 'conflict') {
      return _buildMenuCard('Verifikasi akun', [
        const Text('Status akun perlu dikonfirmasi admin.'),
      ]);
    }
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
            const SnackBar(
              content: Text('Pengajuan Anda sedang diproses oleh admin.'),
            ),
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
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
