import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/kos_model.dart';

import 'property_api.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Ambil SELURUH daftar kos (Digunakan untuk Halaman Utama Pencari / HomeScreen)
  Stream<List<KosModel>> getDaftarKos() => _catalogue();

  // The verified query also picks up approvals for previously private IDs.
  // Legacy documents require individual, rule-checked listeners.
  Stream<List<KosModel>> _catalogue({Set<String>? favorites}) {
    late StreamController<List<KosModel>> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    final legacy = <String, KosModel>{};
    var verified = <String, KosModel>{};
    var stopped = false;
    var waiting = 0;
    void publish() {
      if (!stopped && waiting == 0) {
        controller.add({...legacy, ...verified}.values.toList());
      }
    }

    Future<void> start() async {
      try {
        final ids = favorites ?? (await PropertyApi.legacyIds()).toSet();
        if (stopped) return;
        waiting = ids.length + 1;
        var firstQuery = true;
        final query = _db
            .collection('kos')
            .where('verification_status', isEqualTo: 'verified');
        subscriptions.add(
          query.snapshots().listen((snap) {
            verified = {
              for (final doc in snap.docs)
                if (favorites == null || favorites.contains(doc.id))
                  doc.id: KosModel.fromFirestore(doc.data(), doc.id),
            };
            if (firstQuery) {
              waiting--;
              firstQuery = false;
            }
            publish();
          }, onError: controller.addError),
        );
        for (final id in ids) {
          var first = true;
          void update(KosModel? kos) {
            if (kos == null) {
              legacy.remove(id);
            } else {
              legacy[id] = kos;
            }
            if (first) {
              waiting--;
              first = false;
            }
            publish();
          }

          subscriptions.add(
            publicDetail(id).listen(
              update,
              onError: (Object error) {
                if (error is FirebaseException &&
                    error.code == 'permission-denied') {
                  update(null);
                } else if (!stopped) {
                  controller.addError(error);
                }
              },
            ),
          );
        }
      } catch (error, stack) {
        if (!stopped) controller.addError(error, stack);
      }
    }

    controller = StreamController(
      onListen: start,
      onCancel: () async {
        stopped = true;
        await Future.wait(subscriptions.map((sub) => sub.cancel()));
      },
    );
    return controller.stream;
  }

  Stream<KosModel?> publicDetail(String id) =>
      _db.collection('kos').doc(id).snapshots().map((doc) {
        final data = doc.data();
        if (data == null ||
            (data.containsKey('verification_status') &&
                data['verification_status'] != 'verified')) {
          return null;
        }
        return KosModel.fromFirestore(data, doc.id);
      });

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
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return KosModel.fromFirestore(doc.data(), doc.id);
          }).toList(),
        );
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
  Map<String, dynamic> _submission() => {
    'verification_status': 'pending',
    'telegram_delivery_status': 'queued',
    'verification_submitted_at': FieldValue.serverTimestamp(),
    'verification_updated_at': FieldValue.serverTimestamp(),
    'verified_at': null,
    'rejection_reason': '',
  };

  Future<String> addKost(KosModel kos) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Silakan login kembali.');
    final user = (await _db.collection('users').doc(uid).get()).data();
    if ((user?['roles'] ?? user?['role']) != 'owner') {
      throw StateError('Hanya pemilik yang dapat mendaftarkan kos.');
    }
    final doc = await _db.collection('kos').add({
      ...kos.toFirestore(),
      'user_id': uid,
      'created_at': FieldValue.serverTimestamp(),
      ..._submission(),
    });
    return doc.id;
  }

  Future<void> updateKost(KosModel kos) =>
      _db.collection('kos').doc(kos.id).update(kos.propertyFields());

  Future<void> retryTelegram(String id) async {
    final ref = _db.collection('kos').doc(id);
    await _db.runTransaction((tx) async {
      final data = (await tx.get(ref)).data();
      if (data == null ||
          data['user_id'] != _auth.currentUser?.uid ||
          data['verification_status'] != 'pending') {
        throw StateError('Pengajuan tidak dapat dikirim.');
      }
      if (data['telegram_sent_for'] != null &&
          data['telegram_sent_for'] == data['verification_submitted_at']) {
        return;
      }
      if (data['telegram_delivery_status'] == null ||
          data['telegram_delivery_status'] == 'failed') {
        tx.update(ref, {'telegram_delivery_status': 'queued'});
      }
    });
  }

  Future<void> resubmit(KosModel kos) async {
    final doc = _db.collection('kos').doc(kos.id);
    await _db.runTransaction((tx) async {
      final data = (await tx.get(doc)).data();
      if (data == null ||
          data['user_id'] != _auth.currentUser?.uid ||
          data['verification_status'] != 'rejected') {
        throw StateError('Pengajuan ini tidak dapat diajukan ulang.');
      }
      tx.update(doc, {...kos.propertyFields(), ..._submission()});
    });
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

    final ids = favoriteIds.toSet();
    return _catalogue(favorites: ids);
  }

  // 8. Toggle (Tambah / Hapus) Kos dari Wishlist User
  Future<void> toggleFavorite(String kosId, bool isCurrentlyFavorite) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final userDocRef = _db.collection('users').doc(currentUserId);

    if (isCurrentlyFavorite) {
      // Jika sudah favorit, hapus dari array 'favorites'
      await userDocRef.update({
        'favorites': FieldValue.arrayRemove([kosId]),
      });
    } else {
      // Jika belum, tambahkan ke array 'favorites'
      await userDocRef.update({
        'favorites': FieldValue.arrayUnion([kosId]),
      });
    }
  }
}
