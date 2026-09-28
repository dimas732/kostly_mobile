import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/kos_model.dart';
import '../core/app_theme.dart';
import 'add_edit_kos_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State createState() => _AdminScreenState();
}

class _AdminScreenState extends State {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Owner Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder(
      stream: _firestoreService.getDaftarKos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final daftarKos = snapshot.data ?? [];

        // Hitung Statistik Sederhana
        final int totalKos = daftarKos.length;
        final int totalPutra = daftarKos.where((k) => k.type.toLowerCase() == 'putra').length;
        final int totalPutri = daftarKos.where((k) => k.type.toLowerCase() == 'putri').length;

        return Column(
          children: [
            // 1. KARTU STATISTIK RINGKAS
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  _buildStatCard('Total Kos', totalKos.toString(), Icons.home, AppTheme.primaryBlue),
                  const SizedBox(width: 10),
                  _buildStatCard('Kos Putra', totalPutra.toString(), Icons.male, Colors.orange),
                  const SizedBox(width: 10),
                  _buildStatCard('Kos Putri', totalPutri.toString(), Icons.female, Colors.pink),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. JUDUL DAFTAR KOS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kelola Properti Kos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${daftarKos.length} Item',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),

            // 3. LIST DATA KOS DENGAN AKSI CRUD
            Expanded(
              child: daftarKos.isEmpty
                  ? const Center(child: Text('Belum ada data kos yang ditambahkan.'))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: daftarKos.length,
                itemBuilder: (context, index) {
                  final kost = daftarKos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 1.5,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          kost.image.isNotEmpty
                              ? kost.image
                              : 'https://via.placeholder.com/150',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      title: Text(
                        kost.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Rp ${kost.rentPrice}/bulan'),
                          Text(
                            'Kategori: ${kost.type}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddEditKosScreen(kost: kost),
                                ),
                              );
                            },
                          ),
                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDelete(context, kost),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      ),

      // TOMBOL TAMBAH KOS BARU (+)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Kos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditKosScreen()),
          );
        },
      ),
    );
  }

  // Widget Kartu Statistik Sederhana
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog Konfirmasi Hapus Data
  void _confirmDelete(BuildContext context, KosModel kost) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kos?'),
        content: Text('Apakah kamu yakin ingin menghapus "${kost.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.deleteKos(kost.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${kost.name} berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}