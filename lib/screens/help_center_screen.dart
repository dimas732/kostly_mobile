
import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? selectedAudience;
  String searchQuery = '';

  static const Color primaryGreen = Color(0xFF2B8EFF);
  static const Color darkGreen = Color(0xFF2B8EFF);
  static const Color textColor = Color(0xFF292929);
  static const Color greyColor = Color(0xFF777777);

  final List<HelpArticle> articles = [
    HelpArticle(
      category: 'Produk dan Fitur untuk Penyewa',
      question: 'Bagaimana cara mencari kos di Kostly?',
      icon: Icons.home_work_outlined,
      audience: 'Penyewa Kos',
      content: '''
Kamu bisa mencari kos melalui aplikasi Kostly dengan mengikuti langkah berikut:

1. Buka halaman utama aplikasi Kostly.
2. Masuk ke fitur pencarian kos.
3. Cari kos berdasarkan lokasi atau informasi yang tersedia.
4. Pilih kos yang ingin kamu lihat.
5. Buka halaman detail untuk melihat informasi kos secara lebih lengkap.

Pastikan kamu membaca informasi kos dengan teliti sebelum menentukan pilihan.
''',
    ),
    HelpArticle(
      category: 'Kebijakan dan Panduan',
      question: 'Bagaimana cara menjaga keamanan saat mencari kos?',
      icon: Icons.shield_outlined,
      audience: 'Penyewa Kos',
      content: '''
Keamanan merupakan hal penting saat mencari tempat tinggal.

Berikut beberapa hal yang perlu diperhatikan:

1. Periksa informasi kos secara menyeluruh.
2. Pastikan alamat dan informasi pemilik kos jelas.
3. Jangan memberikan informasi pribadi kepada pihak yang tidak dikenal.
4. Lakukan konfirmasi langsung kepada pemilik kos sebelum mengambil keputusan.
5. Berhati-hatilah terhadap permintaan pembayaran yang tidak jelas.

Selalu pastikan informasi yang kamu terima dapat dipercaya.
''',
    ),
    HelpArticle(
      category: 'Akun Penyewa',
      question: 'Saya lupa password akun penyewa, apa yang harus saya lakukan?',
      icon: Icons.person_outline,
      audience: 'Penyewa Kos',
      content: '''
Jika kamu lupa password akun, kamu dapat mencoba langkah berikut:

1. Buka halaman login Kostly.
2. Periksa apakah tersedia fitur Lupa Password.
3. Ikuti petunjuk pemulihan akun yang ditampilkan.
4. Jika belum berhasil, pastikan informasi akun yang digunakan sudah benar.

Jangan membagikan password kepada orang lain.
''',
    ),
    HelpArticle(
      category: 'Akun Pemilik',
      question: 'Bagaimana cara mengelola informasi akun pemilik?',
      icon: Icons.person_outline,
      audience: 'Pemilik Kos',
      content: '''
Pemilik kos perlu memastikan informasi akun tetap akurat.

Berikut beberapa hal yang dapat diperhatikan:

1. Masuk menggunakan akun pemilik kos.
2. Buka bagian profil atau pengaturan akun.
3. Periksa informasi akun yang ditampilkan.
4. Perbarui informasi apabila fitur pengeditan tersedia.
5. Pastikan informasi yang digunakan tetap aktif dan benar.
''',
    ),
    HelpArticle(
      category: 'Produk dan Fitur untuk Pemilik',
      question: 'Bagaimana cara menambahkan informasi kos?',
      icon: Icons.apartment_outlined,
      audience: 'Pemilik Kos',
      content: '''
Pemilik kos dapat menggunakan fitur pengelolaan kos yang tersedia di aplikasi.

Langkah umum yang dapat dilakukan:

1. Login menggunakan akun pemilik.
2. Buka menu pengelolaan kos.
3. Pilih fitur tambah kos apabila tersedia.
4. Isi informasi kos sesuai kondisi sebenarnya.
5. Periksa kembali informasi sebelum menyimpan data.

Gunakan foto dan deskripsi yang sesuai dengan kondisi kos.
''',
    ),
    HelpArticle(
      category: 'Panduan Keamanan',
      question: 'Bagaimana memastikan informasi kos yang saya pilih?',
      icon: Icons.menu_book_outlined,
      audience: 'Penyewa Kos',
      content: '''
Sebelum memilih kos, perhatikan beberapa informasi berikut:

1. Lokasi dan alamat kos.
2. Harga sewa yang tercantum.
3. Fasilitas yang tersedia.
4. Foto dan deskripsi kos.
5. Informasi pemilik kos.

Jika terdapat informasi yang kurang jelas, lakukan konfirmasi terlebih dahulu kepada pemilik kos.
''',
    ),
    HelpArticle(
      category: 'Syarat dan Ketentuan',
      question: 'Apa saja ketentuan penggunaan aplikasi Kostly?',
      icon: Icons.description_outlined,
      audience: 'Semua Pengguna',
      content: '''
Setiap pengguna Kostly diharapkan menggunakan aplikasi secara bertanggung jawab.

Beberapa hal yang perlu diperhatikan:

1. Menggunakan informasi akun yang benar.
2. Tidak menyalahgunakan fitur aplikasi.
3. Tidak mengunggah informasi kos yang menyesatkan.
4. Menjaga keamanan informasi pribadi.
5. Menggunakan aplikasi sesuai fungsi yang disediakan.

Pengguna diharapkan membaca ketentuan penggunaan yang berlaku.
''',
    ),
  ];

  List<HelpArticle> get filteredArticles {
    return articles.where((article) {
      final matchesAudience = selectedAudience == null ||
          article.audience == selectedAudience ||
          article.audience == 'Semua Pengguna';

      final matchesSearch =
          article.question.toLowerCase().contains(searchQuery) ||
              article.category.toLowerCase().contains(searchQuery) ||
              article.content.toLowerCase().contains(searchQuery);

      return matchesAudience && matchesSearch;
    }).toList();
  }

  List<HelpArticle> get searchResults {
    final query = searchQuery.toLowerCase().trim();

    if (query.isEmpty) return [];

    return articles.where((article) {
      return article.question.toLowerCase().contains(query) ||
          article.category.toLowerCase().contains(query) ||
          article.content.toLowerCase().contains(query) ||
          article.audience.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void selectAudience(String audience) {
    setState(() {
      selectedAudience =
      selectedAudience == audience ? null : audience;
    });
  }

  void openArticle(HelpArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HelpArticleDetailScreen(
              article: article,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 38),
                    const Text(
                      'Hai, ada yang bisa dibantu?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 28),

                    _buildSearchField(),

                    const SizedBox(height: 38),


                    if (searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 30),

                      Text(
                        'Hasil Pencarian (${searchResults.length})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                      const SizedBox(height: 25),

                      if (searchResults.isEmpty)
                        _buildEmptyState()
                      else
                        ...searchResults.map(
                              (article) => _buildArticleItem(article),
                        ),
                    ] else ...[
                      const Text(
                        'Anda bisa telusuri kategori informasi '
                            'sesuai tipe akun berikut ini:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAudienceCard('Pencari Kos'),
                          const SizedBox(width: 12),
                          _buildAudienceCard('Pemilik Kos'),
                        ],
                      ),

                      const SizedBox(height: 40),
                      const Divider(color: Color(0xFFE5E5E5)),
                      const SizedBox(height: 40),

                      const Text(
                        'Paling Sering Dicari',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                      const SizedBox(height: 28),

                      if (filteredArticles.isEmpty)
                        _buildEmptyState()
                      else
                        ...filteredArticles.map(
                              (article) => _buildArticleItem(article),
                        ),
                    ],

                    const SizedBox(height: 20),


                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(
                            context,
                                (route) => route.isFirst,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B8EFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Kembali ke Beranda',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    const SizedBox(height: 20),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/img/logo_kostly(fix).png',
            width: 42,
            height: 42,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Pusat Bantuan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B8EFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF0F0F0),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase().trim();
          });
        },
        decoration: const InputDecoration(
          hintText: 'Masukkan kata pencarian di sini',
          hintStyle: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 29,
            color: textColor,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 12,
          ),
        ),
      ),
    );
  }


  Widget _buildAudienceCard(String title) {
    final isSelected = selectedAudience == title;
    final isPenyewa = title == 'Pencari Kos';

    final Color accentColor = isPenyewa
        ? const Color(0xFF2B8EFF)
        : const Color(0xFFE88B40);

    final Color backgroundColor = isPenyewa
        ? const Color(0xFFE9F2FF)
        : const Color(0xFFFFF0E5);

    final Color iconBackground = isPenyewa
        ? const Color(0xFFD5E7FF)
        : const Color(0xFFFFE1C7);

    return Expanded(
      child: InkWell(
        onTap: () {
          final audience =
          isPenyewa ? 'Penyewa Kos' : 'Pemilik Kos';

          final selectedArticles = articles.where((article) {
            return article.audience == audience ||
                article.audience == 'Semua Pengguna';
          }).toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HelpCategoryScreen(
                title: title,
                articles: selectedArticles,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 145),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : accentColor.withOpacity(0.20),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPenyewa
                          ? Icons.home_outlined
                          : Icons.apartment_outlined,
                      color: accentColor,
                      size: 23,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: accentColor,
                      size: 21,
                    ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF292929),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                isPenyewa
                    ? 'Cari dan pilih kos'
                    : 'Kelola properti kos',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildArticleItem(HelpArticle article) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () => openArticle(article),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 55,
              child: Icon(
                article.icon,
                size: 30,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.category,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.question,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.45,
                      color: Color(0xFF555B65),
                    ),
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'Selengkapnya',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 35),
        child: Column(
          children: [
            const Icon(
              Icons.search_off,
              size: 55,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              'Informasi tidak ditemukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Coba gunakan kata pencarian lainnya.',
              style: TextStyle(
                color: greyColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class HelpCategoryScreen extends StatelessWidget {
  final String title;
  final List<HelpArticle> articles;

  const HelpCategoryScreen({
    super.key,
    required this.title,
    required this.articles,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF292929),
        elevation: 1,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2B8EFF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Pusat Bantuan $title',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF292929),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Temukan jawaban dari pertanyaan yang sering diajukan.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 28),

          if (articles.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Text(
                  'Belum ada artikel bantuan.',
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...articles.map((article) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HelpArticleDetailScreen(
                              article: article,
                            ),
                      ),
                    );
                  },
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 45,
                        child: Icon(
                          article.icon,
                          size: 30,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.category,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF777777),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              article.question,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.45,
                                color: Color(0xFF555B65),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Selengkapnya',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2B8EFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// MODEL ARTIKEL BANTUAN

class HelpArticle {
  final String category;
  final String question;
  final IconData icon;
  final String audience;
  final String content;

  const HelpArticle({
    required this.category,
    required this.question,
    required this.icon,
    required this.audience,
    required this.content,
  });
}

// HALAMAN DETAIL ARTIKEL

class HelpArticleDetailScreen extends StatelessWidget {
  final HelpArticle article;

  const HelpArticleDetailScreen({
    super.key,
    required this.article,
  });

  static const Color primaryGreen = Color(0xFF2B8EFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF292929),
        elevation: 1,
        title: const Text(
          'Pusat Bantuan',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  article.icon,
                  size: 30,
                  color: primaryGreen,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    article.category,
                    style: const TextStyle(
                      fontSize: 14,
                      color: primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            Text(
              article.question,
              style: const TextStyle(
                fontSize: 27,
                height: 1.3,
                fontWeight: FontWeight.bold,
                color: Color(0xFF292929),
              ),
            ),

            const SizedBox(height: 25),

            const Divider(),

            const SizedBox(height: 20),

            Text(
              article.content.trim(),
              style: const TextStyle(
                fontSize: 16,
                height: 1.8,
                color: Color(0xFF444444),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Pusat Bantuan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGreen,
                  side: const BorderSide(color: primaryGreen),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
