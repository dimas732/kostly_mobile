import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _authService = AuthService();
  String _email = '';
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != widget.userId) {
        throw StateError('Sesi pengguna tidak sesuai.');
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final data = snapshot.data();
      if (data == null ||
          FirebaseAuth.instance.currentUser?.uid != widget.userId) {
        throw StateError('Profil tidak tersedia.');
      }
      if (!mounted) return;
      _name.text = UserModel.profileName(data);
      _phone.text = UserModel.profilePhone(data);
      _email = user.email ?? data['email']?.toString() ?? '-';
    } catch (_) {
      if (mounted) {
        _loadError = 'Profil gagal dimuat. Periksa sesi dan koneksi Anda.';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validatePhone(String? value) {
    final phone = (value ?? '').trim();
    final normalized = phone.replaceAll(RegExp(r'[\s()-]'), '');
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(normalized)) {
      return 'Masukkan nomor HP yang valid (8–15 digit).';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await _authService.updateProfile(
        userId: widget.userId,
        name: _name.text,
        phone: _phone.text,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      final message = error.code == 'permission-denied'
          ? 'Tidak memiliki izin untuk memperbarui profil.'
          : 'Gagal menyimpan profil. Periksa koneksi dan coba lagi.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan profil. Coba lagi.')),
      );
    } finally {
      if (mounted && _saving) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Edit Profil'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _name,
            builder: (context, value, child) {
              final name = value.text.trim();
              return CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryBlue,
                child: Text(
                  name.isEmpty ? 'U' : name.characters.first.toUpperCase(),
                  style: const TextStyle(fontSize: 32, color: Colors.white),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Informasi Pribadi',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Perbarui informasi kontak dan nama profil Anda.'),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 100,
                  decoration: _decoration('Nama Lengkap', Icons.person_outline),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Nama wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  decoration: _decoration('Nomor HP', Icons.phone_outlined),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  initialValue: _email,
                  readOnly: true,
                  decoration: _decoration('Email', Icons.lock_outline),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Email digunakan untuk login dan tidak dapat diubah di sini.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan Perubahan'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
