import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/kos_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Ambil SELURUH daftar kos (Digunakan untuk Halaman Utama Pencari / HomeScreen)
  Stream<List<KosModel>> getDaftarKos() {
    return _db
        .collection('kos')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return KosModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList());
  }

  // 2. Ambil daftar kos KHUSUS milik owner yang sedang login (Digunakan untuk AdminScreen)
  Stream<List<KosModel>> getDaftarKosByOwner() {
    final String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _db
        .collection('kos')
        .where('user_id', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return KosModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList());
  }

  // 3. Cari daftar kos berdasarkan nama atau lokasi (Digunakan untuk Fitur Search di HomeScreen)
  Stream<List<KosModel>> searchDaftarKos(String query) {
    return getDaftarKos().map((daftarKos) {
      final lowercaseQuery = query.toLowerCase();
      return daftarKos.where((kos) {
        return kos.name.toLowerCase().contains(lowercaseQuery) ||
            kos.address.toLowerCase().contains(lowercaseQuery);
      }).toList();
    });
  }

  // 4. Tambah Kos Baru (Otomatis menyertakan user_id pemilik saat ini)
  Future<void> addKost(KosModel kos) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    Map<String, dynamic> dataKos = kos.toFirestore();
    dataKos['user_id'] = currentUserId;

    await _db.collection('kos').add(dataKos);
  }

  // 5. Update Data Kos
  Future<void> updateKost(KosModel kos) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    Map<String, dynamic> dataKos = kos.toFirestore();
    dataKos['user_id'] = currentUserId; // Pastikan user_id tetap terikat pada owner aktif

    await _db.collection('kos').doc(kos.id).update(dataKos);
  }

  // 6. Hapus Kos
  Future<void> deleteKos(String idKos) async {
    await _db.collection('kos').doc(idKos).delete();
  }

  // ==========================================
  // FITUR WISHLIST / FAVORIT
  // ==========================================

  // 7. Ambil stream daftar kos yang difavoritkan berdasarkan list ID di dokumen user
  Stream<List<KosModel>> getFavoriteKos(List<String> favoriteIds) {
    if (favoriteIds.isEmpty) {
      return Stream.value([]);
    }

    // Menggunakan FieldPath.documentId untuk mencocokkan ID dokumen kos
    return _db
        .collection('kos')
        .where(FieldPath.documentId, whereIn: favoriteIds)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return KosModel.fromFirestore(
        doc.data(),
        doc.id,
      );
    }).toList());
  }

  // 8. Toggle (Tambah / Hapus) Kos dari Wishlist User
  Future<void> toggleFavorite(String kosId, bool isCurrentlyFavorite) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final userDocRef = _db.collection('users').doc(currentUserId);

    if (isCurrentlyFavorite) {
      // Jika sudah favorit, hapus dari array 'favorites'
      await userDocRef.update({
        'favorites': FieldValue.arrayRemove([kosId])
      });
    } else {
      // Jika belum, tambahkan ke array 'favorites'
      await userDocRef.update({
        'favorites': FieldValue.arrayUnion([kosId])
      });
    }
  }
}