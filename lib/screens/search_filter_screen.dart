import 'package:flutter/material.dart';
import '../models/kos_model.dart';

/// Menyimpan semua pilihan filter pencarian.
class KosFilter {
  static const double maxPrice = 5000000;

  final String query; // nama kos
  final String location; // kota / kecamatan / alamat
  final String type; // Semua, Putra, Putri, Campur
  final RangeValues price;

  const KosFilter({
    this.query = '',
    this.location = '',
    this.type = 'Semua',
    this.price = const RangeValues(0, maxPrice),
  });

  bool get isPriceDefault => price.start == 0 && price.end >= maxPrice;

  /// Dipakai di HomeScreen untuk menyaring daftar kos.
  bool matches(KosModel k) {
    final q = query.toLowerCase().trim();
    final loc = location.toLowerCase().trim();

    if (q.isNotEmpty && !k.name.toLowerCase().contains(q)) return false;
    if (loc.isNotEmpty && !k.address.toLowerCase().contains(loc)) return false;
    if (type != 'Semua' &&
        k.type.toLowerCase().trim() != type.toLowerCase()) {
      return false;
    }
    if (k.rentPrice < price.start) return false;
    if (price.end < maxPrice && k.rentPrice > price.end) return false;
    return true;
  }

  String get label {
    final parts = <String>[
      if (query.trim().isNotEmpty) query.trim(),
      if (location.trim().isNotEmpty) location.trim(),
      if (type != 'Semua') 'Kos $type',
    ];
    return parts.isEmpty ? 'Semua kos' : parts.join(' • ');
  }
}

class SearchFilterScreen extends StatefulWidget {
  final KosFilter initial;

  const SearchFilterScreen({super.key, this.initial = const KosFilter()});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  static const Color _blue = Color(0xFF2B8EFF);
  static const Color _fieldColor = Color(0xFFEBF3FE);

  // Riwayat disimpan di memori selama aplikasi hidup.
  static final List<KosFilter> _history = [];

  late final TextEditingController _queryController;
  late final TextEditingController _locationController;
  late String _type;
  late RangeValues _price;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initial.query);
    _locationController = TextEditingController(text: widget.initial.location);
    _type = widget.initial.type;
    _price = widget.initial.price;
  }

  @override
  void dispose() {
    _queryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _formatRupiah(num amount) {
    final text = amount.round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
          (Match m) => '${m[1]}.',
    );
    return 'Rp $text';
  }

  String get _priceLabel {
    final start = _formatRupiah(_price.start);
    final end = _price.end >= KosFilter.maxPrice
        ? '${_formatRupiah(KosFilter.maxPrice)}+'
        : _formatRupiah(_price.end);
    return '$start - $end / bulan';
  }

  KosFilter get _currentFilter => KosFilter(
    query: _queryController.text,
    location: _locationController.text,
    type: _type,
    price: _price,
  );

  void _clearAll() {
    setState(() {
      _queryController.clear();
      _locationController.clear();
      _type = 'Semua';
      _price = const RangeValues(0, KosFilter.maxPrice);
    });
  }

  void _search() {
    final filter = _currentFilter;
    final hasInput = filter.query.trim().isNotEmpty ||
        filter.location.trim().isNotEmpty ||
        filter.type != 'Semua' ||
        !filter.isPriceDefault;

    if (hasInput) {
      _history.removeWhere((f) => f.label == filter.label);
      _history.insert(0, filter);
      if (_history.length > 5) _history.removeLast();
    }
    Navigator.pop(context, filter);
  }

  void _pickType() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipe Kos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final option in ['Semua', 'Putra', 'Putri', 'Campur'])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option),
                    trailing: _type == option
                        ? const Icon(Icons.check_circle, color: _blue)
                        : const Icon(Icons.circle_outlined, color: Colors.grey),
                    onTap: () {
                      setState(() => _type = option);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickPrice() {
    RangeValues temp = _price;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rentang Harga per Bulan',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatRupiah(temp.start)} - '
                          '${temp.end >= KosFilter.maxPrice ? '${_formatRupiah(KosFilter.maxPrice)}+' : _formatRupiah(temp.end)}',
                      style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    RangeSlider(
                      values: temp,
                      min: 0,
                      max: KosFilter.maxPrice,
                      divisions: 50,
                      activeColor: _blue,
                      onChanged: (v) => setSheetState(() => temp = v),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _price = temp);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Terapkan',
                          style: TextStyle(
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: tutup & hapus semua
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text(
                      'Hapus semua',
                      style: TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Kolom cari nama kos
              _buildField(
                controller: _queryController,
                hint: 'Cari nama kos',
                icon: Icons.search,
              ),
              const SizedBox(height: 14),

              // Kolom lokasi
              _buildField(
                controller: _locationController,
                hint: 'Masukkan kota, kecamatan, atau alamat',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 20),

              // Menu filter
              _buildFilterRow(
                label: _type == 'Semua' ? 'Semua tipe kos' : 'Kos $_type',
                onTap: _pickType,
              ),
              _buildFilterRow(
                label: _price.start == 0 && _price.end >= KosFilter.maxPrice
                    ? 'Semua harga'
                    : _priceLabel,
                onTap: _pickPrice,
              ),

              const SizedBox(height: 28),

              // Tombol cari
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'CARI KOS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Pencarian terakhir
              if (_history.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text(
                  'Pencarian terakhir',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                for (final item in _history)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context, item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _fieldColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.history, color: _blue),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _search(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.black45),
        filled: true,
        fillColor: _fieldColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterRow({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
