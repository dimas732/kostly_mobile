import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/owner_application_model.dart';
import '../services/telegram_service.dart'; // Import service Telegram yang baru dibuat

class OwnerRegistrationScreen extends StatefulWidget {
  final String userId;

  const OwnerRegistrationScreen({super.key, required this.userId});

  @override
  State<OwnerRegistrationScreen> createState() => _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller Data Diri
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Controller Data Properti Kos
  final TextEditingController _kosNameController = TextEditingController();
  final TextEditingController _kosLocationController = TextEditingController();

  // File Gambar (Tanpa Selfie)
  File? _ktpFile;
  File? _propertyProofFile;
  File? _propertyImageFile;

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _fullNameController.dispose();
    _nikController.dispose();
    _phoneController.dispose();
    _kosNameController.dispose();
    _kosLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75, // Kompresi ringan agar upload ke Firebase Storage lebih cepat
    );

    if (pickedFile != null) {
      setState(() {
        if (type == 'ktp') {
          _ktpFile = File(pickedFile.path);
        } else if (type == 'proof') {
          _propertyProofFile = File(pickedFile.path);
        } else if (type == 'property') {
          _propertyImageFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ktpFile == null || _propertyProofFile == null || _propertyImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi ketiga foto dokumen & properti kos!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload ketiga file ke Firebase Storage
      String ktpUrl = await _uploadFileToStorage(_ktpFile!, 'ktp');
      String proofUrl = await _uploadFileToStorage(_propertyProofFile!, 'proof');
      String propertyUrl = await _uploadFileToStorage(_propertyImageFile!, 'property');

      // 2. Susun objek OwnerApplication
      OwnerApplication newApp = OwnerApplication(
        applicationId: widget.userId,
        userId: widget.userId,
        fullName: _fullNameController.text.trim(),
        nik: _nikController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        kosName: _kosNameController.text.trim(),
        kosLocation: _kosLocationController.text.trim(),
        ktpImageUrl: ktpUrl,
        propertyProofUrl: proofUrl,
        propertyImageUrl: propertyUrl,
        status: 'pending',
        rejectionReason: '',
        submittedAt: Timestamp.now(),
      );

      // 3. Simpan pengajuan ke Firestore
      await FirebaseFirestore.instance
          .collection('owner_applications')
          .doc(widget.userId)
          .set(newApp.toMap());

      // 4. Update status verifikasi di dokumen users
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'verificationStatus': 'pending'});

      // 5. Kirim Notifikasi & Tombol Interaktif ke Bot Telegram Admin
      await TelegramService.sendOwnerApplicationNotification(
        userId: widget.userId,
        fullName: _fullNameController.text.trim(),
        nik: _nikController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        kosName: _kosNameController.text.trim(),
        kosLocation: _kosLocationController.text.trim(),
        ktpUrl: ktpUrl,
        proofUrl: proofUrl,
        propertyUrl: propertyUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan berhasil dikirim! Menunggu tinjauan Admin.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim pengajuan: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadFileToStorage(File file, String folderName) async {
    String fileName = '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = FirebaseStorage.instance.ref().child('owner_docs/$folderName/$fileName');
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Daftar Pemilik Kos',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mengunggah dokumen verifikasi...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: DATA IDENTITAS PEMILIK
              _buildSectionTitle('1. Identitas Pemilik'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _fullNameController,
                label: 'Nama Lengkap (Sesuai KTP)',
                hint: 'Contoh: Budi Santoso',
                icon: Icons.person_outline,
                validator: (val) => val == null || val.isEmpty ? 'Nama lengkap wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _nikController,
                label: 'NIK (16 Digit)',
                hint: 'Masukkan 16 digit NIK KTP',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                maxLength: 16,
                validator: (val) => val == null || val.length != 16 ? 'NIK harus berjumlah 16 digit' : null,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _phoneController,
                label: 'Nomor WhatsApp Aktif',
                hint: '08xxxxxxxxxx',
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? 'Nomor WhatsApp wajib diisi' : null,
              ),

              const SizedBox(height: 24),

              // SECTION 2: DATA PROPERTI KOS
              _buildSectionTitle('2. Informasi Properti Kos'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _kosNameController,
                label: 'Nama Kos',
                hint: 'Contoh: Kos Melati Indah',
                icon: Icons.home_work_outlined,
                validator: (val) => val == null || val.isEmpty ? 'Nama kos wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _kosLocationController,
                label: 'Lokasi / Alamat Lengkap Kos',
                hint: 'Jl. Contoh No. 12, Kecamatan, Kota',
                icon: Icons.location_on_outlined,
                maxLines: 3,
                validator: (val) => val == null || val.isEmpty ? 'Alamat lokasi kos wajib diisi' : null,
              ),

              const SizedBox(height: 24),

              // SECTION 3: DOKUMEN & FOTO PENDUKUNG
              _buildSectionTitle('3. Dokumen & Foto Properti'),
              const SizedBox(height: 12),
              _buildImageUploadCard(
                title: 'Foto KTP Asli',
                subtitle: 'Pastikan NIK dan foto terlihat jelas',
                file: _ktpFile,
                onTap: () => _pickImage('ktp'),
              ),
              const SizedBox(height: 12),
              _buildImageUploadCard(
                title: 'Bukti Kepemilikan / Pengelolaan',
                subtitle: 'Foto PBB, Sertifikat, atau Surat Kuasa Kos',
                file: _propertyProofFile,
                onTap: () => _pickImage('proof'),
              ),
              const SizedBox(height: 12),
              _buildImageUploadCard(
                title: 'Foto Bangunan / Kamar Kos',
                subtitle: 'Foto tampak depan bangunan atau interior kamar',
                file: _propertyImageFile,
                onTap: () => _pickImage('property'),
              ),

              const SizedBox(height: 32),

              // TOMBOL SUBMIT
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B8EFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kirim Pengajuan Verifikasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: maxLines == 1 ? Icon(icon, color: const Color(0xFF2B8EFF)) : null,
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2B8EFF), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? const Color(0xFF2B8EFF) : Colors.grey.shade300,
            width: file != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail Preview jika foto sudah dipilih
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FE),
                borderRadius: BorderRadius.circular(10),
                image: file != null
                    ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                    : null,
              ),
              child: file == null
                  ? const Icon(Icons.add_a_photo_outlined, color: Color(0xFF2B8EFF))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file != null ? 'Foto berhasil dipilih (Ketuk untuk ubah)' : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: file != null ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              file != null ? Icons.check_circle : Icons.chevron_right,
              color: file != null ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}