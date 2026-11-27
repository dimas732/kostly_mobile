import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Ditambahkan untuk mengambil UID user aktif

import '../core/app_theme.dart';
import '../models/kos_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/kos_card.dart';
import 'details_kos_screen.dart';
import 'auth/auth_gate.dart';
import 'auth/profile_screen.dart';
import './wishlist_screen.dart';
import 'search_filter_screen.dart'; // 🔹 Halaman pencarian & filter baru

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  late final _catalogue = _firestoreService.getDaftarKos();

  // 🔍 Filter pencarian (nama, lokasi, tipe kos, harga)
  KosFilter _filter = const KosFilter();

  int _selectedBottomNav = 0;

  // Dragging bubble
  double _currentPos = 0.0;
  bool _isDragging = false;

  final List<String> _categories = ['Semua', 'Putra', 'Putri', 'Campur'];

  // True jika ada pencarian / filter yang sedang aktif
  bool get _hasActiveFilter =>
      _filter.query.trim().isNotEmpty ||
      _filter.location.trim().isNotEmpty ||
      _filter.type != 'Semua' ||
      !_filter.isPriceDefault;

  void _openDetail(KosModel kost) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailScreen(kost: kost)),
    );
  }

  Future<void> _handleSignOut() async {
    await AuthService().signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthGate()),
      (route) => false,
    );
  }

  // 🔹 Membuka halaman pencarian & filter
  Future<void> _openSearch() async {
    final result = await Navigator.push<KosFilter>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchFilterScreen(initial: _filter),
      ),
    );

    if (!mounted) return;

    setState(() {
      if (result != null) _filter = result;
      _selectedBottomNav = 0;
      _currentPos = 0.0;
    });
  }

  // Membuka halaman wishlist
  Future<void> _openWishlist() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WishlistScreen()),
    );

    if (!mounted) return;

    setState(() {
      _selectedBottomNav = 0;
      _currentPos = 0.0;
    });
  }

  // Membuka halaman Profil dengan mengambil UID user yang sedang login saat ini
  Future<void> _openProfile() async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: currentUserId),
      ),
    );

    if (!mounted) return;

    setState(() {
      _selectedBottomNav = 0;
      _currentPos = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ambil ID user aktif untuk dikirim ke ProfileScreen pada IndexedStack
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Daftar halaman utama berdasarkan urutan ikon BottomNavigationBar:
    final List<Widget> pages = [
      _buildHomeContent(),
      const Center(
        child: Text(
          'Halaman Cari / Explore',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
      const WishlistScreen(),
      ProfileScreen(userId: currentUserId),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _selectedBottomNav, children: pages),

      // Dynamic Fluid Drag Navigation Bar
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
                      pos = pos.clamp(0.0, (items.length - 1).toDouble());

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

                      // Menu Cari -> buka halaman pencarian & filter
                      if (nearestIndex == 1) {
                        _openSearch();
                      }

                      // Menu Profil
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
                            left: (_currentPos * itemWidth) + 4,
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
                                      const SizedBox(width: 4),
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

  // Widget terpisah khusus untuk isi halaman utama Home (Katalog, Search, & Kategori)
  Widget _buildHomeContent() {
    return SafeArea(
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

                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Kost',
                            style: TextStyle(
                              color: Color(0xFF1A82FF),
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: 'Ly',
                            style: TextStyle(
                              color: Color(0xFF55A9FF),
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Keluar',
                      onPressed: _handleSignOut,
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: Color(0xFFEF5350),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFDECEC),
                        fixedSize: const Size(40, 40),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Search Bar (ketuk untuk membuka halaman pencarian & filter)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: _openSearch,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _hasActiveFilter
                            ? _filter.label
                            : 'Cari kos atau lokasi...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: _hasActiveFilter
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                    if (_hasActiveFilter)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _filter = const KosFilter()),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.clear,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: Colors.grey,
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. Category Filter Chips (terhubung dengan filter tipe kos)
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _filter.type == category;

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
                        _filter = KosFilter(
                          query: _filter.query,
                          location: _filter.location,
                          type: category,
                          price: _filter.price,
                        );
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 4. Katalog Kos (Grid Firestore + filter nama, lokasi, tipe, harga)
          Expanded(
            child: StreamBuilder<List<KosModel>>(
              stream: _catalogue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi kesalahan: ${snapshot.error}'),
                  );
                }

                final List<KosModel> semuaKos = snapshot.data ?? [];
                final List<KosModel> daftarKos = semuaKos
                    .where(_filter.matches)
                    .toList();

                if (daftarKos.isEmpty) {
                  return const Center(
                    child: Text(
                      'Kos tidak ditemukan',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: daftarKos.length,
                  itemBuilder: (context, index) {
                    final kost = daftarKos[index];
                    return KosCard(kost: kost, onTap: () => _openDetail(kost));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
