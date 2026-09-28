import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/kos_model.dart';
import '../services/firestore_service.dart';
import '../core/app_theme.dart';

class AddEditKosScreen extends StatefulWidget {
  final KosModel? kost;

  const AddEditKosScreen({super.key, this.kost});

  @override
  State createState() => _AddEditKosScreenState();
}

class _AddEditKosScreenState extends State<AddEditKosScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _rentPriceController;
  late TextEditingController _imageController;
  late TextEditingController _descriptionController;

  late TextEditingController _waterCostController;
  late TextEditingController _wifiCostController;
  late TextEditingController _tokenCostController;

  String _selectedType = 'Putra';
  String _selectedStatus = 'available';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Membaca data dari widget.kost
    _nameController = TextEditingController(text: widget.kost?.name ?? '');
    _addressController = TextEditingController(text: widget.kost?.address ?? '');
    _rentPriceController = TextEditingController(text: widget.kost?.rentPrice.toString() ?? '');
    _imageController = TextEditingController(text: widget.kost?.image ?? '');
    _descriptionController = TextEditingController(text: widget.kost?.description ?? '');

    _selectedType = (widget.kost?.type.isNotEmpty == true) ? widget.kost!.type : 'Putra';
    _selectedStatus = (widget.kost?.status.isNotEmpty == true) ? widget.kost!.status : 'available';

    _waterCostController = TextEditingController(
      text: widget.kost?.reccuringCost['air']?.toString() ?? '0',
    );
    _wifiCostController = TextEditingController(
      text: widget.kost?.reccuringCost['wifi']?.toString() ?? '0',
    );
    _tokenCostController = TextEditingController(
      text: widget.kost?.electricalCost['token']?.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _rentPriceController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    _waterCostController.dispose();
    _wifiCostController.dispose();
    _tokenCostController.dispose();
    super.dispose();
  }

  Future _saveKos() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final Map reccuringMap = {
        'air': int.tryParse(_waterCostController.text.trim()) ?? 0,
        'wifi': int.tryParse(_wifiCostController.text.trim()) ?? 0,
      };

      final Map electricalMap = {
        'token': int.tryParse(_tokenCostController.text.trim()) ?? 0,
      };

      final newKos = KosModel(
        id: widget.kost?.id ?? '',
        userId: widget.kost?.userId.isNotEmpty == true ? widget.kost!.userId : currentUserId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        rentPrice: int.parse(_rentPriceController.text.trim()),
        type: _selectedType,
        status: _selectedStatus,
        image: _imageController.text.trim(),
        description: _descriptionController.text.trim(),
        reccuringCost: reccuringMap,
        electricalCost: electricalMap,
        createdAt: widget.kost?.createdAt,
      );

      if (widget.kost == null) {
        await _firestoreService.addKost(newKos);
      } else {
        await _firestoreService.updateKost(newKos);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.kost == null ? 'Kos berhasil ditambahkan!' : 'Data kos berhasil diperbarui!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.kost != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Data Kos' : 'Tambah Kos Baru'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_nameController, 'Nama Kos', 'Contoh: Kos Ketintang Indah'),
              const SizedBox(height: 14),
              _buildTextField(_addressController, 'Alamat Lengkap', 'Jl. Ketintang No. 12, Surabaya'),
              const SizedBox(height: 14),
              _buildTextField(
                _rentPriceController,
                'Harga Sewa Utama (Rp/Bulan)',
                '750000',
                isNumber: true,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tipe Kos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField(
                          value: _selectedType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: ['Putra', 'Putri', 'Campur'].map((t) {
                            return DropdownMenuItem(value: t, child: Text(t));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedType = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status Kamar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'available', child: Text('Tersedia')),
                            DropdownMenuItem(value: 'full', child: Text('Penuh')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatus = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildTextField(_imageController, 'URL Gambar Kos', 'https://...'),
              const SizedBox(height: 14),

              const Text('Biaya Tambahan & Listrik (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_waterCostController, 'Air (Rp/bln)', '0', isNumber: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(_wifiCostController, 'WiFi (Rp/bln)', '0', isNumber: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(_tokenCostController, 'Listrik (Rp)', '0', isNumber: true),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildTextField(_descriptionController, 'Deskripsi Kos', 'Fasilitas, aturan, dll.', maxLines: 3),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _saveKos,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    isEdit ? 'Simpan Perubahan' : 'Tambah Kos Sekarang',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      String hint, {
        bool isNumber = false,
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          validator: (val) {
            if (!isNumber && (val == null || val.isEmpty)) {
              return '$label wajib diisi';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}