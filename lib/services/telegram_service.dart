import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class TelegramService {
  static const String _botToken = '9136558902:AAEMHJjQ111W2CvsePGod3YO46_-VoIJJ74';
  static const String _adminChatId = '-1004354520855';

  static Future<void> sendOwnerApplicationNotification({
    required String userId,
    required String fullName,
    required String nik,
    required String phoneNumber,
    required String kosName,
    required String kosLocation,
    required File ktpFile,
    required File proofFile,
    required File propertyFile,
  }) async {
    // 1. Kirim ketiga foto dokumen langsung ke chat Telegram Admin
    await _sendPhoto(ktpFile, '🪪 Foto KTP - $fullName');
    await _sendPhoto(proofFile, '📄 Bukti Kepemilikan - $kosName');
    await _sendPhoto(propertyFile, '🏠 Foto Properti - $kosName');

    // 2. Kirim detail teks + Tombol Approve/Reject
    final url = Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage');
    final String message = '''
📢 <b>PENGAJUAN OWNER KOS BARU!</b>

👤 <b>Nama:</b> $fullName
🆔 <b>NIK:</b> $nik
📞 <b>No HP / WA:</b> $phoneNumber

🏠 <b>Nama Kos:</b> $kosName
📍 <b>Lokasi:</b> $kosLocation

Silakan tinjau ketiga foto di atas dan berikan keputusan:
''';

    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _adminChatId,
          'text': message,
          'parse_mode': 'HTML',
          'reply_markup': {
            'inline_keyboard': [
              [
                {'text': '✅ Setujui (Approve)', 'callback_data': 'approve_$userId'},
                {'text': '❌ Tolak (Reject)', 'callback_data': 'reject_$userId'}
              ]
            ]
          }
        }),
      );
    } catch (e) {
      print('Error mengirim notifikasi Telegram: $e');
    }
  }

  // Helper untuk mengunggah file foto langsung ke Telegram Bot API
  static Future<void> _sendPhoto(File photoFile, String caption) async {
    final url = Uri.parse('https://api.telegram.org/bot$_botToken/sendPhoto');
    var request = http.MultipartRequest('POST', url)
      ..fields['chat_id'] = _adminChatId
      ..fields['caption'] = caption
      ..files.add(await http.MultipartFile.fromPath('photo', photoFile.path));

    await request.send();
  }
}