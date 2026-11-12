import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Wajib ada untuk decode Base64
import '../models/kos_model.dart';
import '../services/firestore_service.dart';
import '../core/app_theme.dart';

class KosCard extends StatelessWidget {
  final KosModel kost;
  final VoidCallback onTap;

  const KosCard({super.key, required this.kost, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final FirestoreService firestoreService = FirestoreService();

    // Mengambil gambar pertama dari list 'images' (Base64)
    // Pastikan di model KosModel kamu nama list gambarnya 'images'
    // (Jika di model namanya berbeda, sesuaikan misal kost.imageUrls)

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Gambar Base64 dari Lokal
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 115,
                    width: double.infinity,
                    child: _buildImageWidget(),
                  ),
                ),

                // 2. Informasi Detail (Nama, Alamat, Harga)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kost.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          kost.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Rp ${kost.rentPrice.toStringAsFixed(0)} / bln',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Tombol Ikon Wishlist di Pojok Kanan Atas
            Positioned(
              top: 8,
              right: 8,
              child: currentUserId.isEmpty
                  ? const SizedBox.shrink()
                  : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  bool isFavorite = false;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final List<dynamic> favorites = data?['favorites'] ?? [];
                    isFavorite = favorites.contains(kost.id);
                  }

                  return InkWell(
                    onTap: () {
                      firestoreService.toggleFavorite(kost.id, isFavorite);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[700],
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk merender Base64 atau gambar standar
  Widget _buildImageWidget() {
    try {
      // Periksa apakah list gambar tidak kosong
      // (Catatan: Ganti kost.imageUrls dengan nama properti di KosModel kamu jika menggunakan nama lain, misal kost.images)
      if (kost.images.isNotEmpty) {
        String imgStr = kost.images.first;

        // Jika string mengandung format data:image (Base64)
        if (imgStr.contains('base64,')) {
          final base64String = imgStr.split(',').last;
          final decodedBytes = base64Decode(base64String);
          return Image.memory(
            decodedBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
          );
        } else {
          // Jika ternyata berupa URL biasa
          return Image.network(
            imgStr,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
          );
        }
      }
    } catch (e) {
      print('Error decoding image: $e');
    }
    return _errorPlaceholder();
  }

  Widget _errorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.home, color: Colors.grey, size: 32),
    );
  }
}