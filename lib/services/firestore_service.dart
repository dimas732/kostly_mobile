import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kos_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream daftar semua kos secara real-time
  Stream<List<KosModel>> getDaftarKos() {
    return _db.collection('kost').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => KosModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // fitur search
  Stream<List<KosModel>> searchDaftarKos(String query) {
    // Mengambil seluruh data, lalu difilter secara lokal agar pencarian lebih fleksibel (case-insensitive)
    return _db.collection('kos').snapshots().map((snapshot) {
      List<KosModel> semuaKos = snapshot.docs
          .map((doc) => KosModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (query.isEmpty) return semuaKos;

      return semuaKos.where((kos) {
        final namaKos = kos.name.toLowerCase();
        final lokasiKos = kos.address.toLowerCase();
        final searchQuery = query.toLowerCase();

        return namaKos.contains(searchQuery) || lokasiKos.contains(searchQuery);
      }).toList();
    });
  }

  // Ambil detail 1 kos berdasarkan ID (untuk Halaman Detail nanti)
  Future<KosModel?> getKosById(String id) async {
    final doc = await _db.collection('kost').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return KosModel.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  Future addKost(KosModel kost) async{
    await _db.collection('kost').add(kost.toMap());
  }

  Future updateKost(KosModel kost) async{
    await _db.collection('kost').doc(kost.id).update(kost.toMap());
  }

  Future deleteKos(String kostId) async {
    await _db.collection('kost').doc(kostId).delete();
  }
}