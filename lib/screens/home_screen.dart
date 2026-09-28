import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/kos_model.dart';
import '../widgets/kos_card.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State {
  final FirestoreService _firestoreService = FirestoreService();

  int _selectedBottomNav = 0;
  String _selectedCategory = 'Semua';

  // dragging bubble
  double _currentPos = 0.0;
  bool _isDragging = false;

  final List _categories = ['Semua', 'Putra', 'Putri', 'Campur'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Judul & Notifikasi & Logout)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/img/logo_kostly(fix).png',
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'KostLy',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none_rounded, size: 26),
                        color: Colors.black87,
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, size: 24, color: Colors.redAccent),
                        onPressed: () async {
                          await AuthService().signOut();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari kos...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. Category Filter Chips
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryBlue,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.transparent),
                      ),
                      showCheckmark: false,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 4. Katalog Kos (Grid Firestore)
            Expanded(
              child: StreamBuilder(
              stream: _firestoreService.getDaftarKos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                }

                List daftarKos = snapshot.data ?? [];

                if (_selectedCategory != 'Semua') {
                  daftarKos = daftarKos
                      .where((kost) => kost.type.toLowerCase() == _selectedCategory.toLowerCase())
                      .toList();
                }

                if (daftarKos.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada kos kategori $_selectedCategory',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: daftarKos.length,
                  itemBuilder: (context, index) {
                    final kost = daftarKos[index];
                    return KosCard(
                      kost: kost,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Memilih ${kost.name}')),
                        );
                      },
                    );
                  },
                );
              },
              ),
            ),
          ],
        ),
      ),

      // 5. Dynamic Fluid Drag Navigation Bar
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75), // Efek frosted glass pekat
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final items = [
                      {'icon': Icons.home_rounded, 'label': 'Home'},
                      {'icon': Icons.search_rounded, 'label': 'Cari'},
                      {'icon': Icons.favorite_rounded, 'label': 'Favorit'},
                      {'icon': Icons.person_rounded, 'label': 'Profil'},
                    ];

                    final double itemWidth = constraints.maxWidth / items.length;

                    // Fungsi menghitung posisi desimal berdasarkan koordinat jari
                    void updatePositionFromOffset(Offset localPosition) {
                      // Hitung offset agar posisi bubble tepat berada di tengah ujung jari
                      double pos = (localPosition.dx - (itemWidth / 2)) / itemWidth;
                      // Batasi nilai agar tidak kebablasan keluar dari nav bar (0.0 s/d 3.0)
                      pos = pos.clamp(0.0, items.length - 1.0);

                      setState(() {
                        _currentPos = pos;
                      });
                    }

                    // Fungsi untuk mengunci (snap) posisi ke item terdekat saat jari dilepas
                    void snapToNearest() {
                      int nearestIndex = _currentPos.round();
                      setState(() {
                        _currentPos = nearestIndex.toDouble();
                        _selectedBottomNav = nearestIndex;
                        _isDragging = false;
                      });
                    }

                    return GestureDetector(
                      onHorizontalDragStart: (details) {
                        setState(() {
                          _isDragging = true; // Matikan durasi animasi agar merespon instant
                        });
                        updatePositionFromOffset(details.localPosition);
                      },
                      onHorizontalDragUpdate: (details) {
                        updatePositionFromOffset(details.localPosition);
                      },
                      onHorizontalDragEnd: (details) {
                        snapToNearest(); // Melepas jari -> animasi snap ke tab terdekat
                      },
                      onTapDown: (details) {
                        setState(() {
                          _isDragging = false; // Aktifkan animasi smooth saat di-tap
                        });
                        updatePositionFromOffset(details.localPosition);
                        snapToNearest();
                      },
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // 💡 1. BUBBLE KACA YANG MENGIKUTI POSISI JARI SECARA DINAMIS
                          AnimatedPositioned(
                            duration: _isDragging
                                ? Duration.zero // Instant tanpa delay saat ditarik jari
                                : const Duration(milliseconds: 300), // Membal halus saat di-tap / dilepas
                            curve: Curves.easeOutCubic,
                            left: _currentPos * itemWidth + 4, // Geser posisi horizontal X
                            top: 4,
                            bottom: 4,
                            width: itemWidth - 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppTheme.primaryBlue.withOpacity(0.35),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),

                          // 💡 2. IKON DAN TEKS
                          Row(
                            children: List.generate(items.length, (index) {
                              // Hitung jarak bubble ke ikon ini (0.0 = pas di atas ikon)
                              final double distance = (_currentPos - index).abs();

                              // Warna & Opacity transisi halus berdasarkan jarak bubble
                              final double activeFactor = (1.0 - distance).clamp(0.0, 1.0);

                              return Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      items[index]['icon'] as IconData,
                                      // Gradasi warna ikon dari Hitam ke Primary secara instan/halus
                                      color: Color.lerp(
                                        Colors.black45,
                                        AppTheme.primaryBlue,
                                        activeFactor,
                                      ),
                                      size: 21,
                                    ),

                                    // Teks memudar (*fade in/out*) sesuai jarak bubble dengan jari
                                    if (activeFactor > 0.1) ...[
                                      const SizedBox(height: 2),
                                      Opacity(
                                        opacity: activeFactor,
                                        child: Text(
                                          items[index]['label'] as String,
                                          style: TextStyle(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}