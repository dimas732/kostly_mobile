import 'dart:convert'; // 🔹 Wajib untuk konversi base64

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/kos_model.dart';
import '../models/electricity_pricing.dart';
import '../widgets/electricity_pricing_editor.dart';
import '../services/firestore_service.dart';
import '../core/app_theme.dart';

class AddEditKosScreen extends StatefulWidget {
  final KosModel? kost;
  const AddEditKosScreen({super.key, this.kost});

  @override
  State<AddEditKosScreen> createState() => _AddEditKosScreenState();
}

class _AddEditKosScreenState extends State<AddEditKosScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controller Text Form
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _airController;
  late TextEditingController _wifiController;
  late ElectricityPricing _electricityPricing;

  String _selectedType = 'Putra';
  String _selectedStatus = 'available';

  // State untuk Multi Image & Base64
  final ImagePicker _picker = ImagePicker();
  List<String> _localImageBase64List = []; // Menyimpan string Base64 foto baru
  List<String> _existingImages = []; // Menyimpan foto lama (jika mode edit)
  bool _isLoading = false;

  String? _validateCost(String? value) {
    final amount = int.tryParse(value?.trim() ?? '');
    if (amount == null || amount < 0) return 'Masukkan angka 0 atau lebih';
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _airController.dispose();
    _wifiController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.kost?.name ?? '');
    _addressController = TextEditingController(
      text: widget.kost?.address ?? '',
    );
    _priceController = TextEditingController(
      text: widget.kost?.rentPrice.toString() ?? '',
    );
    _descController = TextEditingController(
      text: widget.kost?.description ?? '',
    );

    _airController = TextEditingController(
      text: widget.kost?.reccuringCost['air']?.toString() ?? '0',
    );
    _wifiController = TextEditingController(
      text: widget.kost?.reccuringCost['wifi']?.toString() ?? '0',
    );
    _electricityPricing =
        widget.kost?.electricity ?? const ElectricityPricing();

    if (widget.kost != null) {
      _selectedType = widget.kost!.type;
      _selectedStatus = widget.kost!.status;
      _existingImages = List.from(widget.kost!.images);
    }
  }

  // 🔹 Fungsi Pilih Banyak Gambar & Konversi ke Base64
  // 🔹 Perbarui fungsi _pickAndConvertImages dengan kompresi ukuran
  Future<void> _pickAndConvertImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 600, // 👈 Batasi lebar maksimal gambar agar ukurannya kecil
        maxHeight: 600, // 👈 Batasi tinggi maksimal gambar
        imageQuality: 50, // 👈 Kompres kualitas gambar ke 50% agar hemat kapasitas Firestore
      );

      if (pickedFiles.isNotEmpty) {
        for (var file in pickedFiles) {
          Uint8List imageBytes = await file.readAsBytes();
          String base64String =
              'data:image/jpeg;base64,${base64Encode(imageBytes)}';

          setState(() {
            _localImageBase64List.add(base64String);
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal memilih/kompres gambar: $e");
    }
  }

  // 🔹 Simpan Data ke Firestore
  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_existingImages.isEmpty && _localImageBase64List.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih minimal 1 foto kos!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gabungkan gambar lama dan gambar baru berformat Base64
      List<String> finalImages = [..._existingImages, ..._localImageBase64List];

      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final kosData = KosModel(
        id: widget.kost?.id ?? '',
        userId: userId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        rentPrice: int.tryParse(_priceController.text) ?? 0,
        type: _selectedType,
        status: _selectedStatus,
        description: _descController.text.trim(),
        images: finalImages, // 👈 Tersimpan aman langsung di Firestore
        reccuringCost: {
          'air': int.tryParse(_airController.text) ?? 0,
          'wifi': int.tryParse(_wifiController.text) ?? 0,
        },
        electricalCost: {
          'listrik': _electricityPricing.mode == ElectricityMode.fixed
              ? _electricityPricing.fixedMonthly
              : 0,
        },
        electricityPricing: _electricityPricing,
        createdAt: widget.kost?.createdAt,
      );

      if (widget.kost == null) {
        await _firestoreService.addKost(kosData);
      } else {
        await _firestoreService.updateKost(kosData);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper untuk menampilkan gambar baik dari Base64 maupun URL lama
  Widget _buildImageThumbnail(String imagePath, VoidCallback onDelete) {
    Widget imageWidget;
    if (imagePath.startsWith('data:image')) {
      try {
        final base64Str = imagePath.split(',').last;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      } catch (e) {
        imageWidget = Container(
          width: 100,
          height: 100,
          color: Colors.grey,
          child: const Icon(Icons.broken_image),
        );
      }
    } else if (imagePath.isNotEmpty) {
      imageWidget = Image.network(
        imagePath,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    } else {
      imageWidget = Container(width: 100, height: 100, color: Colors.grey);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageWidget,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.kost == null ? 'Tambah Kos Baru' : 'Edit Kos'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Kos
                    const Text(
                      'Nama Kos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Kos Ketintang Indah',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Nama kos tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),

                    // Alamat Lengkap
                    const Text(
                      'Alamat Lengkap',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'Jl. Ketintang No. 12, Surabaya',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Alamat tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),

                    // Harga Sewa
                    const Text(
                      'Harga Sewa Utama (Rp/Bulan)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '750000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _validateCost,
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Tipe & Status
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tipe Kos',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedType,
                                items: ['Putra', 'Putri', 'Campur']
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedType = val!),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status Kamar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                items: [
                                  const DropdownMenuItem(
                                    value: 'available',
                                    child: Text('Tersedia'),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'full',
                                    child: Text('Penuh'),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _selectedStatus = val!),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // BAGIAN UPLOAD FOTO (BASE64)
                    const Text(
                      'Foto-Foto Kos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Tombol Tambah Foto
                          GestureDetector(
                            onTap: _pickAndConvertImages,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tambah',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Foto Lama
                          ..._existingImages.asMap().entries.map((entry) {
                            int index = entry.key;
                            return _buildImageThumbnail(entry.value, () {
                              setState(() => _existingImages.removeAt(index));
                            });
                          }),

                          // Foto Baru (Base64)
                          ..._localImageBase64List.asMap().entries.map((entry) {
                            int index = entry.key;
                            return _buildImageThumbnail(entry.value, () {
                              setState(
                                () => _localImageBase64List.removeAt(index),
                              );
                            });
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Biaya Tambahan & Listrik
                    const Text(
                      'Biaya Tambahan per Bulan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Isi 0 jika gratis atau sudah termasuk sewa. Tarif ini digunakan pada kalkulator pencari kos.',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _airController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: _validateCost,
                            decoration: InputDecoration(
                              labelText: 'Air (Rp/bln)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _wifiController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: _validateCost,
                            decoration: InputDecoration(
                              labelText: 'WiFi (Rp/bln)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ElectricityPricingEditor(
                      initialValue: _electricityPricing,
                      onChanged: (pricing) => _electricityPricing = pricing,
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi Kos
                    const Text(
                      'Deskripsi Kos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Fasilitas, aturan, dll.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Tombol Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveForm,
                        child: Text(
                          widget.kost == null
                              ? 'Tambah Kos Sekarang'
                              : 'Simpan Perubahan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
