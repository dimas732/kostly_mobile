import 'package:flutter/material.dart';

import 'dart:ui';

import '../services/firestore_service.dart';
import '../widgets/kos_card.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'auth/profil.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  int _selectedBottomNav = 0;
  String _selectedCategory = 'Semua';

  // Dragging bubble
  double _currentPos = 0.0;
  bool _isDragging = false;

  final List<String> _categories = ['Semua', 'Putra', 'Putri', 'Campur'];

  // Membuka halaman Profil
  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilScreen()),
    );

    if (!mounted) return;

    setState(() {
      _selectedBottomNav = 0;
      _currentPos = 0.0;
    });
  }

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
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          size: 26,
                        ),
                        color: Colors.black87,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout,
                          size: 24,
                          color: Colors.redAccent,
                        ),
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
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
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
                    return Center(
                      child: Text('Terjadi kesalahan: ${snapshot.error}'),
                    );
                  }

                  List daftarKos = snapshot.data ?? [];

                  if (_selectedCategory != 'Semua') {
                    daftarKos = daftarKos.where((kost) {
                      return kost.type.toLowerCase() ==
                          _selectedCategory.toLowerCase();
                    }).toList();
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                  color: Colors.white.withOpacity(0.75),
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

                    final double itemWidth =
                        constraints.maxWidth / items.length;

                    // Menghitung posisi bubble berdasarkan koordinat jari
                    void updatePositionFromOffset(Offset localPosition) {
                      double pos =
                          (localPosition.dx - (itemWidth / 2)) / itemWidth;

                      pos = pos.clamp(0.0, items.length - 1.0);

                      setState(() {
                        _currentPos = pos;
                      });
                    }

                    // Mengunci posisi bubble ke menu terdekat
                    void snapToNearest() {
                      int nearestIndex = _currentPos.round();

                      setState(() {
                        _currentPos = nearestIndex.toDouble();
                        _selectedBottomNav = nearestIndex;
                        _isDragging = false;
                      });

                      // Jika menu Profil dipilih
                      if (nearestIndex == 3) {
                        _openProfile();
                      }
                    }

                    return GestureDetector(
                      onHorizontalDragStart: (details) {
                        setState(() {
                          _isDragging = true;
                        });

                        updatePositionFromOffset(details.localPosition);
                      },
                      onHorizontalDragUpdate: (details) {
                        updatePositionFromOffset(details.localPosition);
                      },
                      onHorizontalDragEnd: (details) {
                        snapToNearest();
                      },
                      onTapDown: (details) {
                        setState(() {
                          _isDragging = false;
                        });

                        updatePositionFromOffset(details.localPosition);

                        snapToNearest();
                      },
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // 1. Bubble kaca
                          AnimatedPositioned(
                            duration: _isDragging
                                ? Duration.zero
                                : const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            left: _currentPos * itemWidth + 4,
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

                          // 2. Ikon dan teks navigasi
                          Row(
                            children: List.generate(items.length, (index) {
                              final double distance = (_currentPos - index)
                                  .abs();

                              final double activeFactor = (1.0 - distance)
                                  .clamp(0.0, 1.0);

                              return Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      items[index]['icon'] as IconData,
                                      color: Color.lerp(
                                        Colors.black45,
                                        AppTheme.primaryBlue,
                                        activeFactor,
                                      ),
                                      size: 21,
                                    ),

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
