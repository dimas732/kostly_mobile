import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream untuk memantau perubahan status auth (login / logout) secara real-time
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get User ID yang sedang aktif
  User? get currentUser => _auth.currentUser;

  // 1. FITUR REGISTER
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role, // 'seeker' atau 'owner'
  }) async {
    try {
      // Buat akun baru di Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Buat objek UserModel sesuai ERD
      UserModel newUser = UserModel (
        uid: uid,
        name: name,
        email: email,
        roles: role,
        phone_number: phoneNumber,
      );

      // Simpan data profil ke koleksi 'users' di Firestore menggunakan UID
      await _db.collection('users').doc(uid).set({
        ...newUser.toFirestore(),
        'created_at': FieldValue.serverTimestamp(),
      });

      return null; // Null menandakan registrasi berhasil tanpa error
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Terjadi kesalahan saat registrasi';
    } catch (e) {
      return 'Gagal mendaftar: ${e.toString()}';
    }
  }

  // 2. FITUR LOGIN
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Null menandakan login berhasil
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Email tidak terdaftar.';
      } else if (e.code == 'wrong-password') {
        return 'Password salah.';
      }
      return e.message ?? 'Gagal melakukan login.';
    } catch (e) {
      return 'Terjadi kesalahan: ${e.toString()}';
    }
  }

  // 3. FITUR LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}