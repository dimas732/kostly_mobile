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