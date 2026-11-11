import 'dart:convert'; // 🔹 Wajib untuk decode Base64
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/kos_model.dart';

class DetailScreen extends StatefulWidget {
  final KosModel kost;

  const DetailScreen({super.key, required this.kost});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _currentImageIndex = 0; // 🔹 Menyimpan indeks foto yang sedang aktif di slider

  // Helper format angka ke Rupiah, contoh: 1500000 -> Rp 1.500.000
  String _formatRupiah(num amount) {
    final formatted = amount.round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
          (Match m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Slider Gambar dengan app bar yang ikut ter-scroll
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageSlider(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama & tipe
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.kost.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.kost.type,
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Alamat
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.kost.address,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.3),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Harga
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Harga sewa',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        Text(
                          '${_formatRupiah(widget.kost.rentPrice)} / bulan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Deskripsi
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.kost.description.isEmpty ? 'Belum ada deskripsi.' : widget.kost.description,
                    style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),

      // Tombol aksi di bawah
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hubungi pemilik ${widget.kost.name}')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Hubungi Pemilik',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Widget Slider untuk Mendukung Banyak Foto + Indikator Titik
  Widget _buildImageSlider() {
    final images = widget.kost.images;

    final placeholder = Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.home_work_outlined, size: 56, color: Colors.grey),
      ),
    );

    if (images.isEmpty) return placeholder;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return _renderSingleImage(images[index]);
          },
        ),

        // Indikator Titik (Dots) jika foto lebih dari satu
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(
                      _currentImageIndex == entry.key ? 0.9 : 0.4,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // 🔹 Helper untuk Menampilkan Gambar (Mendukung Base64 Lokal & URL Network)
  // 🔹 Helper untuk Menampilkan Gambar (Lebih Fleksibel untuk Base64 & Network)
  Widget _renderSingleImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.home_work_outlined, size: 56, color: Colors.grey)),
      );
    }

    try {
      String base64Str = imagePath;
      if (imagePath.startsWith('data:image')) {
        base64Str = imagePath.split(',').last;
      }

      // Coba decode sebagai Base64
      final bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } catch (e) {
      // Jika gagal decode Base64, anggap sebagai URL internet biasa
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
  }
}