import 'dart:convert';
import 'package:http/http.dart' as http;

class TelegramService {
  // Ganti dengan Token dan Chat ID milikmu
  static const String _botToken = '9136558902:AAEMHJjQ111W2CvsePGod3YO46_-VoIJJ74';
  static const String _chatId = '5261794663';

  static Future<void> sendOwnerApplicationNotification({
    required String userId,
    required String fullName,
    required String nik,
    required String phoneNumber,
    required String kosName,
    required String kosLocation,
    required String ktpUrl,
    required String proofUrl,
    required String propertyUrl,
  }) async {
    final String url = 'https://api.telegram.org/bot$_botToken/sendMessage';

    // Format pesan yang rapi menggunakan HTML
    final String message = '''
🏠 <b>PENGAJUAN PEMILIK KOS BARU</b>

👤 <b>Nama:</b> $fullName
🆔 <b>NIK:</b> <code>$nik</code>
📱 <b>WhatsApp:</b> $phoneNumber
🏢 <b>Nama Kos:</b> $kosName
📍 <b>Lokasi:</b> $kosLocation

📎 <b>Dokumen Verifikasi:</b>
• <a href="$ktpUrl">Lihat Foto KTP</a>
• <a href="$proofUrl">Lihat Bukti Kepemilikan</a>
• <a href="$propertyUrl">Lihat Foto Properti Kos</a>

<i>Silakan tinjau dokumen di atas dan pilih tindakan:</i>
''';

    // Membuat tombol Inline Keyboard di bawah pesan Telegram
    final Map<String, dynamic> replyMarkup = {
      'inline_keyboard': [
        [
          {
            'text': '✅ Approve',
            'callback_data': 'approve_$userId',
          },
          {
            'text': '❌ Reject',
            'callback_data': 'reject_$userId',
          }
        ]
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _chatId,
          'text': message,
          'parse_mode': 'HTML',
          'disable_web_page_preview': true,
          'reply_markup': replyMarkup,
        }),
      );

      if (response.statusCode != 200) {
        print('Gagal kirim ke Telegram: ${response.body}');
      }
    } catch (e) {
      print('Error TelegramService: $e');
    }
  }
}