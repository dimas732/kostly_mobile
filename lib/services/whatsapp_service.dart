class WhatsAppService {
  /// Nomor lokal Indonesia diubah menjadi format internasional untuk wa.me.
  static String? normalizePhone(String phone) {
    final cleaned = phone.trim().replaceAll(RegExp(r'[\s()\-]'), '');
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(cleaned)) return null;
    var digits = cleaned.replaceFirst(RegExp(r'^\+'), '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    } else if (digits.startsWith('8')) {
      digits = '62$digits';
    }
    if (!RegExp(r'^[1-9][0-9]{7,14}$').hasMatch(digits)) return null;
    return digits;
  }

  static Uri? chatUri(String phone, String kosName) {
    final number = normalizePhone(phone);
    if (number == null) return null;
    return Uri.https('wa.me', '/$number', {
      'text':
          'Halo, saya tertarik dengan kos $kosName di KostLy. '
          'Apakah masih tersedia?',
    });
  }
}
