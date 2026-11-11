import 'dart:convert'; // 🔹 Wajib untuk decode Base64
import 'package:flutter/material.dart';
import '../models/kos_model.dart';

class KosCard extends StatelessWidget {
  final KosModel kost;
  final VoidCallback onTap;

  const KosCard({super.key, required this.kost, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Ambil gambar pertama dari list, jika kosong berikan string kosong
    final String imagePath = kost.images.isNotEmpty ? kost.images.first : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 COVER GAMBAR KOS (Mendukung Base64 & Network URL)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  width: double.infinity,
                  child: _buildCardImage(imagePath),
                ),
              ),
            ),

            // INFORMASI KOS (Nama, Alamat, Harga)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kost.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kost.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${kost.rentPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Helper Cerdas untuk Menampilkan Gambar Base64 atau URL
  Widget _buildCardImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.home_work_outlined, size: 36, color: Colors.grey),
        ),
      );
    }

    try {
      String base64Str = imagePath;
      if (imagePath.startsWith('data:image')) {
        base64Str = imagePath.split(',').last;
      }

      final bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
      );
    } catch (e) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, size: 36, color: Colors.grey),
          ),
        ),
      );
    }
  }
}