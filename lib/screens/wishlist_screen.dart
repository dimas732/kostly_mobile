
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final List<Map<String, String>> _wishlist = [
    {
      'name': 'Kost Melati',
      'address': 'Surabaya, Jawa Timur',
      'price': 'Rp 850.000',
      'type': 'Putri',
    },
    {
      'name': 'Kost Harmoni',
      'address': 'Sidoarjo, Jawa Timur',
      'price': 'Rp 1.200.000',
      'type': 'Campur',
    },
    {
      'name': 'Kost Anggrek',
      'address': 'Surabaya, Jawa Timur',
      'price': 'Rp 950.000',
      'type': 'Putra',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Wishlist Saya',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.favorite_rounded,
                  color: AppTheme.primaryBlue,
                  size: 28,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_wishlist.length} kost tersimpan',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: _wishlist.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              itemCount: _wishlist.length,
              separatorBuilder: (_, _) =>
              const SizedBox(height: 14),
              itemBuilder: (context, index) {
                return _buildWishlistCard(
                  _wishlist[index],
                  index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistCard(
      Map<String, String> kost,
      int index,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 105,
            height: 115,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.home_work_rounded,
              color: AppTheme.primaryBlue,
              size: 42,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kost['name']!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  kost['type']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        kost['address']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${kost['price']} / bulan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(
              Icons.favorite_rounded,
              color: Colors.redAccent,
            ),
            onPressed: () {
              setState(() {
                _wishlist.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 76,
            color: AppTheme.primaryBlue.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Wishlist',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kost yang kamu sukai akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
