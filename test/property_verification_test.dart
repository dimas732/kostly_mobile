import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kost_ly/models/kos_model.dart';
import 'package:kost_ly/models/user_model.dart';

void main() {
  test('Legacy status and both recurring cost spellings survive parsing', () {
    for (final key in ['reccuring_cost', 'recurring_cost']) {
      final kos = KosModel.fromFirestore({
        key: {'wifi': 123},
      }, 'legacy');
      expect(kos.verificationStatus, isNull);
      expect(kos.toFirestore().containsKey('verification_status'), isFalse);
      expect(kos.propertyFields()['reccuring_cost']['wifi'], 123);
    }
  });
  test('Ordinary edits exclude ownership, timestamps and decisions', () {
    final time = Timestamp.fromMillisecondsSinceEpoch(1000);
    final kos = KosModel.fromFirestore({
      'verification_status': 'verified',
      'verified_at': time,
    }, 'id');
    expect(kos.toFirestore()['verified_at'], time);
    expect(kos.copyWith().verifiedAt, time.toDate());
    expect(kos.copyWith(verifiedAt: null).verifiedAt, isNull);
    expect(kos.propertyFields().keys, isNot(contains('user_id')));
    expect(kos.propertyFields().keys, isNot(contains('verified_at')));
    expect(kos.propertyFields().keys, isNot(contains('verification_status')));
  });
  test(
    'Account status supports both writers and exposes unresolved conflicts',
    () {
      expect(
        UserModel.accountStatus({
          'verification_status': 'none',
          'verificationStatus': 'pending',
        }),
        'pending',
      );
      expect(
        UserModel.accountStatus({'verification_status': 'verified'}),
        'verified',
      );
      expect(
        UserModel.accountStatus({
          'verification_status': 'verified',
          'verificationStatus': 'rejected',
        }),
        'conflict',
      );
    },
  );
}
