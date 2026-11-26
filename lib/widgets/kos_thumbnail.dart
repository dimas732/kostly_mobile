import 'dart:convert';

import 'package:flutter/material.dart';

Widget kosThumbnail(String imagePath) {
  if (imagePath.isEmpty) {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  try {
    String base64Str = imagePath;

    // Jika string mengandung header data:image, bersihkan dulu untuk mengambil kodenya saja
    if (imagePath.startsWith('data:image')) {
      base64Str = imagePath.split(',').last;
    }

    // Decode string Base64 menjadi bytes
    final bytes = base64Decode(base64Str);
    return Image.memory(
      bytes,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
      width: 60,
      height: 60,
      fit: BoxFit.cover,
    );
  } catch (e) {
    // Jika gagal decode Base64, coba anggap sebagai URL biasa (Network Image)
    return Image.network(
      imagePath,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: 60,
        height: 60,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
