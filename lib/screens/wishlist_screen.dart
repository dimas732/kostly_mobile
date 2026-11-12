import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_theme.dart';
import '../models/kos_model.dart';
import '../services/firestore_service.dart';
import '../widgets/kos_card.dart';
import 'details_kos_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  void _openDetail(BuildContext context, KosModel kost) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(kost: kost),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Favorit Saya',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: currentUserId.isEmpty
          ? const Center(
        child: Text(
          'Silakan login terlebih dahulu untuk melihat favorit',
          style: TextStyle(color: Colors.grey),
        ),
      )
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('Belum ada kos favorit'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final List<dynamic> favoriteIds = userData?['favorites'] ?? [];

          if (favoriteIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada kos yang disukai',
                    style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          // Menggunakan method getFavoriteKos dari FirestoreService
          return StreamBuilder<List<KosModel>>(
            stream: firestoreService.getFavoriteKos(favoriteIds.cast<String>()),
            builder: (context, kosSnapshot) {
              if (kosSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!kosSnapshot.hasData || kosSnapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Kos favorit tidak ditemukan atau sudah dihapus',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final List<KosModel> favoriteKosList = kosSnapshot.data!;

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemCount: favoriteKosList.length,
                itemBuilder: (context, index) {
                  final kost = favoriteKosList[index];
                  return KosCard(
                    kost: kost,
                    onTap: () => _openDetail(context, kost),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}