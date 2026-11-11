import 'package:flutter/material.dart';
import 'auth/login_screen.dart';

// 1. Model Data untuk Setiap Slide
class OnboardingItem {
  final String tag;
  final String title;
  final String description;
  final String imagePath;

  OnboardingItem({
    required this.tag,
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 2. Daftar Konten Slide
  final List _slides = [
    OnboardingItem(
      tag: 'Satu Aplikasi untuk Semua Kos',
      title: 'FIND YOUR\nPERFECT KOST',
      description: 'Cari dan temukan kamar kos yang sesuai lokasi, anggaran, dan kebutuhan harianmu tanpa perlu muter-muter.',
      imagePath: 'assets/img/kos1.jpeg',
    ),
    OnboardingItem(
      tag: 'Tanpa Biaya Tersembunyi',
      title: 'TRANSPARENT &\nCLEAR PRICING',
      description: 'Dapatkan rincian lengkap biaya sewa, air, Wi-Fi, hingga estimasi listrik secara terbuka sebelum memilih.',
      imagePath: 'assets/img/kos2.jpeg', // Ganti dengan gambar kamar/interior
    ),
    OnboardingItem(
      tag: 'Khusus Pemilik Kos',
      title: 'MANAGE YOUR\nPROPERTY EASILY',
      description: 'Atur ketersediaan kamar, catat pengeluaran, dan pantau status kosmu langsung dari dashboard admin.',
      imagePath: 'assets/img/kos1.jpeg', // Ganti dengan gambar properti/owner
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Jika sudah di slide terakhir, pindah ke LoginScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _slides.length,
        itemBuilder: (context, index) {
          final item = _slides[index];

          return Stack(
            children: [
              // 🖼️ Background Image
              Positioned.fill(
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                ),
              ),

              // 🎨 Gradient Overlay Gelap
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.40),
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // 📱 Konten
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),

                      // 🏷️ Tag Pill + Avatar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 44,
                              height: 22,
                              child: Stack(
                                children: const [
                                  Positioned(
                                    left: 0,
                                    child: CircleAvatar(
                                      radius: 11,
                                      backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=1'),
                                    ),
                                  ),
                                  Positioned(
                                    left: 12,
                                    child: CircleAvatar(
                                      radius: 11,
                                      backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=2'),
                                    ),
                                  ),
                                  Positioned(
                                    left: 24,
                                    child: CircleAvatar(
                                      radius: 11,
                                      backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=3'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.tag.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🔤 Judul Utama
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 📝 Deskripsi
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 🔘 Dynamic Dot Indicators (Garis Berubah Mengikuti Page)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (dotIndex) {
                          final bool isActive = dotIndex == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 26 : 14,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 28),

                      // 🚀 Tombol Lanjut / Mulai Sekarang
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _onNextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            _currentPage == _slides.length - 1 ? 'Get Started' : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}