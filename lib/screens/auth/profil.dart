
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../core/app_theme.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Controller untuk setiap field profil
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  late Future<UserModel> _profileFuture;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _getProfile();
  }

  // Mengambil data pengguna berdasarkan UID
  Future<UserModel> _getProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Pengguna belum login.');
    }

    final document = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!document.exists || document.data() == null) {
      throw Exception('Data profil tidak ditemukan.');
    }

    return UserModel.fromFirestore(
      document.data()!,
      document.id,
    );
  }

  // Mengisi controller dengan data Firestore
  void _initializeForm(UserModel user) {
    if (_isInitialized) return;

    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phone_number;

    _isInitialized = true;
  }

  // Mengaktifkan mode edit
  void _editProfile() {
    setState(() {
      _isEditing = true;
    });
  }

  // Membatalkan perubahan
  void _cancelEdit(UserModel user) {
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phone_number;

    setState(() {
      _isEditing = false;
    });
  }

  // Menyimpan perubahan profil
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    // Validasi field kosong
    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      _showMessage('Semua field harus diisi.');
      return;
    }

    // Validasi format email
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      _showMessage('Format email tidak valid.');
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Pengguna belum login.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Perbarui email Firebase Authentication jika berubah
      if (email != user.email) {
        await user.updateEmail(email);
      }

      // Perbarui data pengguna di Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'email': email,
        'phone_number': phone,
      });

      if (!mounted) return;

      setState(() {
        _profileFuture = _getProfile();
        _isEditing = false;
        _isInitialized = false;
      });

      _showMessage('Profil berhasil diperbarui.');
    } on FirebaseAuthException catch (e) {
      String message;

      if (e.code == 'requires-recent-login') {
        message =
            'Silakan login ulang sebelum mengganti email.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email sudah digunakan akun lain.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else {
        message = e.message ?? 'Gagal memperbarui email.';
      }

      _showMessage(message);
    } catch (e) {
      _showMessage('Gagal memperbarui profil: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Logout
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun KostLy?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();

      if (!mounted) return;

      // Kembali ke halaman utama agar AuthGate
      // dapat menampilkan LoginScreen
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // Menampilkan pesan
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<UserModel>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text('Gagal memuat data profil.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _profileFuture = _getProfile();
                          _isInitialized = false;
                        });
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            final user = snapshot.data!;

            _initializeForm(user);

            return Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _circleButton(
                        icon: Icons.arrow_back,
                        onPressed: () {
                          if (_isEditing) {
                            _cancelEdit(user);
                          }

                          Navigator.pop(context);
                        },
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Profil',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),

                        // FOTO PROFIL
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 126,
                                    height: 126,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade200,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 75,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 4,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Foto profil',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 42),

                        // NAMA LENGKAP
                        _buildLabel('Nama Lengkap'),
                        _buildTextField(
                          controller: _nameController,
                          enabled: _isEditing,
                        ),

                        const SizedBox(height: 22),

                        // EMAIL
                        _buildLabel('Email'),
                        _buildTextField(
                          controller: _emailController,
                          enabled: _isEditing,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 22),

                        // NOMOR TELEPON
                        _buildLabel('No Telepon'),
                        _buildTextField(
                          controller: _phoneController,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 42),

                        // TOMBOL EDIT / SIMPAN
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : _isEditing
                                    ? _saveProfile
                                    : _editProfile,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(
                                color: AppTheme.primaryBlue,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isEditing ? 'Simpan' : 'Edit',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),

                        // TOMBOL BATAL
                        if (_isEditing) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: TextButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _cancelEdit(user),
                              child: const Text('Batal'),
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // TOMBOL KELUAR
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Keluar',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Label input
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black,
        ),
      ),
    );
  }

  // Field profil
  Widget _buildTextField({
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 15,
        color: enabled ? Colors.black : Colors.white,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled
            ? Colors.white
            : AppTheme.primaryBlue,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primaryBlue,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primaryBlue,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Tombol bulat pada header
  Widget _circleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        icon: Icon(icon),
      ),
    );
  }
}
