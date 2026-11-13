import 'package:flutter_test/flutter_test.dart';
import 'package:kost_ly/services/whatsapp_service.dart';

void main() {
  test('Nomor Indonesia diseragamkan untuk WhatsApp', () {
    for (final phone in [
      '081234567890',
      '+62 812-3456-7890',
      '6281234567890',
      '81234567890',
    ]) {
      expect(WhatsAppService.normalizePhone(phone), '6281234567890');
    }
    expect(WhatsAppService.normalizePhone('+1 (202) 555-0123'), '12025550123');
  });

  test('Nomor kosong atau rusak tidak membuat tautan', () {
    for (final phone in [
      '',
      '08123abc',
      '123',
      '000',
      '+62+81234567890',
      '1234567890123456',
    ]) {
      expect(WhatsAppService.chatUri(phone, 'Kos Uji'), isNull);
    }
  });

  test('Pesan dengan karakter khusus tetap utuh dalam tautan', () {
    const name = 'Kos Melati & Mawar #1';
    final uri = WhatsAppService.chatUri('081234567890', name)!;
    expect(uri.scheme, 'https');
    expect(uri.host, 'wa.me');
    expect(uri.path, '/6281234567890');
    expect(uri.queryParameters['text'], contains(name));
  });
}
