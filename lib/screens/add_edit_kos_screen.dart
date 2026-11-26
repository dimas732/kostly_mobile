import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/kos_model.dart';
import '../services/firestore_service.dart';
import '../core/app_theme.dart'; // Sesuaikan path folder app_theme.dart jika berbeda

class AddEditKosScreen extends StatefulWidget {
  final KosModel? kost;

  final bool resubmit;
  const AddEditKosScreen({super.key, this.kost, this.resubmit = false});

  @override
  State<AddEditKosScreen> createState() => _AddEditKosScreenState();
}

class _AddEditKosScreenState extends State<AddEditKosScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0; // 0: Data Kos, 1: Kamar Kos, 2: Foto Kos
  bool _isSaving = false;
  bool _isPickingImages = false;

  static const int _maxImages = 5;

  // --- STAGE 1: DATA KOS ---
  late final TextEditingController _namaKosController;
  late final TextEditingController _hargaController;
  late final TextEditingController _alamatController;
  late final TextEditingController _deskripsiController;
  late String _tipeKos;
  bool? _isIncludeListrik;

  final List<String> _opsiTipeKos = ['Putra', 'Putri', 'Campur'];
  final List<String> _opsiFasilitasArea = [
    'WiFi',
    'Dapur Bersama',
    'Kulkas Bersama',
    'Dispenser Bersama',
    'Parkir Motor',
    'Parkir Mobil',
    'CCTV 24 Jam',
    'Ruang Jemur',
  ];
  late Set<String> _selectedFasilitasArea;

  // --- STAGE 2: DATA KAMAR ---
  late final TextEditingController _totalKamarController;
  late final TextEditingController _kamarTersediaController;
  late final TextEditingController _ukuranKamarController;
  String? _selectedKamarMandi;

  final List<String> _opsiKamarMandi = ['K. Mandi Dalam', 'K. Mandi Luar'];
  final List<String> _opsiFasilitasKamar = [
    'Kasur',
    'Bantal & Guling',
    'Lemari Baju',
    'Meja Belajar',
    'AC',
    'Kipas Angin',
    'Jendela',
    'Ventilasi',
  ];
  late Set<String> _selectedFasilitasKamar;

  // --- STAGE 3: UPLOAD MULTIPLE IMAGES (BASE64) ---
  late List<String> _imagesBase64;

  @override
  void initState() {
    super.initState();
    final kos = widget.kost;

    _namaKosController = TextEditingController(text: kos?.name ?? '');
    _hargaController = TextEditingController(
      text: (kos != null && kos.rentPrice > 0) ? kos.rentPrice.toString() : '',
    );
    _alamatController = TextEditingController(text: kos?.address ?? '');
    _deskripsiController = TextEditingController(text: kos?.description ?? '');

    _tipeKos = _opsiTipeKos.contains(kos?.type) ? kos!.type : 'Campur';
    _isIncludeListrik = kos != null ? kos.includeListrik : null;
    _selectedFasilitasArea = Set<String>.from(kos?.fasilitasArea ?? const []);

    _totalKamarController = TextEditingController(
      text: (kos != null && kos.totalKamar > 0)
          ? kos.totalKamar.toString()
          : '',
    );
    _kamarTersediaController = TextEditingController(
      text: kos != null ? kos.kamarTersedia.toString() : '',
    );
    _ukuranKamarController = TextEditingController(
      text: kos?.ukuranKamar ?? '',
    );

    final existingKamar = List<String>.from(kos?.fasilitasKamar ?? const []);
    for (final km in _opsiKamarMandi) {
      if (existingKamar.contains(km)) {
        _selectedKamarMandi = km;
        existingKamar.remove(km);
        break;
      }
    }
    _selectedFasilitasKamar = Set<String>.from(existingKamar);

    _imagesBase64 = List<String>.from(kos?.images ?? const []);
  }

  @override
  void dispose() {
    _namaKosController.dispose();
    _hargaController.dispose();
    _alamatController.dispose();
    _deskripsiController.dispose();
    _totalKamarController.dispose();
    _kamarTersediaController.dispose();
    _ukuranKamarController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_namaKosController.text.trim().isEmpty) {
        _showMessage('Nama kos wajib diisi.');
        return false;
      }
      if (_alamatController.text.trim().isEmpty) {
        _showMessage('Alamat kos wajib diisi.');
        return false;
      }
      final harga = int.tryParse(_hargaController.text.trim()) ?? 0;
      if (harga <= 0) {
        _showMessage('Masukkan harga sewa per bulan yang valid.');
        return false;
      }
      if (_isIncludeListrik == null) {
        _showMessage(
          'Pilih apakah harga sewa sudah termasuk listrik atau tidak.',
        );
        return false;
      }
    } else if (step == 1) {
      final total = int.tryParse(_totalKamarController.text.trim()) ?? 0;
      final tersedia = int.tryParse(_kamarTersediaController.text.trim()) ?? -1;

      if (total <= 0) {
        _showMessage('Total kamar harus lebih dari 0.');
        return false;
      }
      if (tersedia < 0 || tersedia > total) {
        _showMessage('Kamar tersedia harus antara 0 dan $total.');
        return false;
      }
      if (_selectedKamarMandi == null) {
        _showMessage('Pilih tipe kamar mandi terlebih dahulu.');
        return false;
      }
    }
    return true;
  }

  void _handleNext() {
    if (_isSaving) return;

    if (!_validateStep(_currentStep)) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _saveKos();
    }
  }

  void _handleBack() {
    if (_isSaving) return;

    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _pickMultipleImages() async {
    if (_isPickingImages || _isSaving) return;

    final remaining = _maxImages - _imagesBase64.length;
    if (remaining <= 0) {
      _showMessage('Maksimal $_maxImages foto per kos.');
      return;
    }

    setState(() => _isPickingImages = true);

    try {
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 55,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFiles.isEmpty) return;

      final selectedFiles = pickedFiles.take(remaining).toList();
      final List<String> encodedList = [];

      for (final file in selectedFiles) {
        final bytes = await file.readAsBytes();
        final base64Str = base64Encode(bytes);
        final lower = file.path.toLowerCase();
        final mime = lower.endsWith('.png') ? 'image/png' : 'image/jpeg';
        encodedList.add('data:$mime;base64,$base64Str');
      }

      if (!mounted) return;
      setState(() {
        _imagesBase64.addAll(encodedList);
      });

      if (pickedFiles.length > remaining) {
        _showMessage(
          'Hanya $remaining foto pertama yang ditambahkan (maksimal $_maxImages foto).',
        );
      }
    } catch (e) {
      _showMessage('Gagal mengambil gambar: $e');
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  void _removeImageAt(int index) {
    if (_isSaving) return;
    setState(() {
      _imagesBase64.removeAt(index);
    });
  }

  Future<void> _saveKos() async {
    if (!_validateStep(0) || !_validateStep(1)) {
      if (!_validateStep(0)) {
        setState(() => _currentStep = 0);
      } else {
        setState(() => _currentStep = 1);
      }
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showMessage('Sesi login tidak ditemukan. Silakan login ulang.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final harga = int.parse(_hargaController.text.trim());
      final totalKamar = int.parse(_totalKamarController.text.trim());
      final kamarTersedia = int.parse(_kamarTersediaController.text.trim());

      final fasilitasKamarGabungan = <String>[
        if (_selectedKamarMandi != null) _selectedKamarMandi!,
        ..._selectedFasilitasKamar,
      ];

      final statusKos = kamarTersedia > 0 ? 'available' : 'full';

      final kosModel = KosModel(
        id: widget.kost?.id ?? '',
        verificationStatus: widget.kost == null
            ? 'pending'
            : widget.kost!.verificationStatus,
        name: _namaKosController.text.trim(),
        address: _alamatController.text.trim(),
        description: _deskripsiController.text.trim(),
        rentPrice: harga,
        status: widget.kost?.status ?? statusKos,
        type: _tipeKos,
        userId: widget.kost?.userId.isNotEmpty == true
            ? widget.kost!.userId
            : currentUser.uid,
        createdAt: widget.kost?.createdAt ?? DateTime.now(),
        images: List<String>.from(_imagesBase64),
        listrikCost: widget.kost?.listrikCost ?? 0,
        airCost: widget.kost?.airCost ?? 0,
        wifiCost: widget.kost?.wifiCost ?? 0,
        includeListrik: _isIncludeListrik ?? false,
        fasilitasKamar: fasilitasKamarGabungan,
        fasilitasArea: _selectedFasilitasArea.toList(),
        totalKamar: totalKamar,
        kamarTersedia: kamarTersedia,
        ukuranKamar: _ukuranKamarController.text.trim().isEmpty
            ? null
            : _ukuranKamarController.text.trim(),
      );

      if (widget.kost == null) {
        await _firestoreService.addKost(kosModel);
      } else if (widget.resubmit) {
        await _firestoreService.resubmit(kosModel);
      } else {
        await _firestoreService.updateKost(kosModel);
      }
      final message = widget.kost == null || widget.resubmit
          ? 'Kos tersimpan. Pengajuan masuk antrean Telegram.'
          : 'Perubahan data kos berhasil disimpan!';
      if (!mounted) return;
      _showMessage(message);
      Navigator.of(context).pop(true);
    } catch (e) {
      _showMessage('Gagal menyimpan data kos: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.kost != null;
    // Mengambil primary color dari tema aktif (AppTheme) secara aman
    final Color primaryBlue = AppTheme.primaryBlue;
    final Color lightTheme = primaryBlue.withValues(alpha: 0.12);

    return PopScope(
      canPop: !_isSaving && _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isSaving && _currentStep > 0) {
          setState(() => _currentStep--);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: _handleBack,
          ),
          title: Text(
            isEdit ? 'Edit Iklan Kos' : 'Tambah Iklan Kos',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: Column(
          children: [
            _buildStepperHeader(primaryBlue),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildCurrentStage(primaryBlue, lightTheme),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(primaryBlue),
      ),
    );
  }

  Widget _buildStepperHeader(Color primaryBlue) {
    const titles = ['Data Kos', 'Kamar Kos', 'Foto Kos'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: List.generate(titles.length, (index) {
          final isDone = index < _currentStep;
          final isActive = index == _currentStep;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < titles.length - 1 ? 8 : 0,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDone || isActive)
                              ? primaryBlue
                              : Colors.white,
                          border: Border.all(
                            color: (isDone || isActive)
                                ? primaryBlue
                                : Colors.grey.shade400,
                          ),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          titles[index],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: (isDone || isActive)
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: (isDone || isActive)
                          ? primaryBlue
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStage(Color primaryBlue, Color lightTheme) {
    switch (_currentStep) {
      case 0:
        return _buildStage1DataKos(primaryBlue, lightTheme);
      case 1:
        return _buildStage2KamarKos(primaryBlue, lightTheme);
      default:
        return _buildStage3FotoKos(primaryBlue);
    }
  }

  Widget _buildStage1DataKos(Color primaryBlue, Color lightTheme) {
    return Column(
      children: [
        _buildCard(
          title: 'Informasi Dasar Kos',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _namaKosController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama Kos *',
                  hintText: 'Contoh: Kos Ketintang Indah',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hargaController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Harga Sewa per Bulan (Rp) *',
                  hintText: 'Contoh: 850000',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _alamatController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap',
                  hintText: 'Contoh: Jl. Ketintang Madya No. 21',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _deskripsiController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi & Catatan Tambahan',
                  hintText: 'Informasi aturan kos, akses jalan, dll.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tipe Kos',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _opsiTipeKos.map((tipe) {
                  return _buildPillChip(
                    label: tipe,
                    selected: _tipeKos == tipe,
                    primaryBlue: primaryBlue,
                    lightTheme: lightTheme,
                    onTap: () => setState(() => _tipeKos = tipe),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildCard(
          title: 'Kebijakan Biaya Listrik *',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPillChip(
                label: 'Termasuk Listrik',
                icon: Icons.bolt,
                selected: _isIncludeListrik == true,
                primaryBlue: primaryBlue,
                lightTheme: lightTheme,
                onTap: () => setState(() => _isIncludeListrik = true),
              ),
              _buildPillChip(
                label: 'Tidak Termasuk Listrik',
                icon: Icons.power_off_outlined,
                selected: _isIncludeListrik == false,
                primaryBlue: primaryBlue,
                lightTheme: lightTheme,
                onTap: () => setState(() => _isIncludeListrik = false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildCard(
          title: 'Fasilitas Area Kos',
          child: Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _opsiFasilitasArea.map((fasilitas) {
              final selected = _selectedFasilitasArea.contains(fasilitas);
              return _buildPillChip(
                label: fasilitas,
                selected: selected,
                primaryBlue: primaryBlue,
                lightTheme: lightTheme,
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedFasilitasArea.remove(fasilitas);
                    } else {
                      _selectedFasilitasArea.add(fasilitas);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStage2KamarKos(Color primaryBlue, Color lightTheme) {
    return Column(
      children: [
        _buildCard(
          title: 'Jumlah & Ukuran Kamar',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _totalKamarController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Kamar *',
                        hintText: 'Contoh: 12',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _kamarTersediaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kamar Tersedia *',
                        hintText: 'Contoh: 4',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ukuranKamarController,
                decoration: const InputDecoration(
                  labelText: 'Ukuran Kamar (Opsional)',
                  hintText: 'Contoh: 3 x 4 meter',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildCard(
          title: 'Tipe Kamar Mandi *',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _opsiKamarMandi.map((tipeKm) {
              return _buildPillChip(
                label: tipeKm,
                icon: Icons.bathtub_outlined,
                selected: _selectedKamarMandi == tipeKm,
                primaryBlue: primaryBlue,
                lightTheme: lightTheme,
                onTap: () => setState(() => _selectedKamarMandi = tipeKm),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _buildCard(
          title: 'Fasilitas Dalam Kamar',
          child: Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _opsiFasilitasKamar.map((fasilitas) {
              final selected = _selectedFasilitasKamar.contains(fasilitas);
              return _buildPillChip(
                label: fasilitas,
                selected: selected,
                primaryBlue: primaryBlue,
                lightTheme: lightTheme,
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedFasilitasKamar.remove(fasilitas);
                    } else {
                      _selectedFasilitasKamar.add(fasilitas);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStage3FotoKos(Color primaryBlue) {
    return _buildCard(
      title: 'Upload Foto Kos (Multiple)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih beberapa foto sekaligus dari perangkatmu (maksimal $_maxImages foto).',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_isPickingImages || _isSaving)
                  ? null
                  : _pickMultipleImages,
              icon: _isPickingImages
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryBlue,
                      ),
                    )
                  : Icon(
                      Icons.add_photo_alternate_outlined,
                      color: primaryBlue,
                    ),
              label: Text(
                _isPickingImages
                    ? 'Memproses foto...'
                    : 'Pilih Banyak Foto (${_imagesBase64.length}/$_maxImages)',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_imagesBase64.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 36,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada foto yang dipilih.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _imagesBase64.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) =>
                  _buildImageTile(_imagesBase64[index], index),
            ),
        ],
      ),
    );
  }

  Widget _buildImageTile(String imageStr, int index) {
    Widget preview;

    if (imageStr.startsWith('http://') || imageStr.startsWith('https://')) {
      preview = Image.network(
        imageStr,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    } else {
      final commaIdx = imageStr.indexOf(',');
      final rawBase64 = commaIdx != -1
          ? imageStr.substring(commaIdx + 1)
          : imageStr;
      try {
        final bytes = base64Decode(rawBase64);
        preview = Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image)),
        );
      } catch (_) {
        preview = const Center(child: Icon(Icons.broken_image));
      }
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox.expand(child: preview),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImageAt(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 15, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildPillChip({
    required String label,
    IconData? icon,
    required bool selected,
    required Color primaryBlue,
    required Color lightTheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? lightTheme : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? primaryBlue : Colors.grey.shade300,
            width: selected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? primaryBlue : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? primaryBlue : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(Color primaryBlue) {
    final isLastStep = _currentStep == 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _handleBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _currentStep == 0 ? 'Batal' : 'Sebelumnya',
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isLastStep
                            ? (widget.resubmit ? 'Ajukan Ulang' : 'Simpan Kos')
                            : 'Berikutnya',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
