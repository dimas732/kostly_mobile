class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone_number;
  final String roles;
  final String verification_status;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone_number,
    required this.roles,
    required this.verification_status,
  });

  static String accountStatus(Map<String, dynamic> data) {
    String? read(String key) {
      final value = data[key]?.toString().trim().toLowerCase();
      return value == null || value == '' || value == 'none' ? null : value;
    }

    final stored = read('verification_status');
    final workflow = read('verificationStatus');
    if (stored != null && workflow != null && stored != workflow) {
      return 'conflict';
    }
    return workflow ?? stored ?? 'none';
  }

  // Data profil lama dapat menggunakan nama field camelCase.
  static String profileName(Map<String, dynamic> data) =>
      _firstProfileValue(data, ['fullName', 'name']);

  static String profilePhone(Map<String, dynamic> data) =>
      _firstProfileValue(data, ['phoneNumber', 'phone_number', 'phone']);

  static String _firstProfileValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  // Hanya field profil yang boleh diubah. Sinkronkan alias jika sudah ada.
  static Map<String, dynamic> profileUpdates(
    Map<String, dynamic> current, {
    required String name,
    required String phone,
  }) {
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    return {
      'name': cleanName,
      'phone_number': cleanPhone,
      if (current.containsKey('fullName')) 'fullName': cleanName,
      if (current.containsKey('phoneNumber')) 'phoneNumber': cleanPhone,
      if (current.containsKey('phone')) 'phone': cleanPhone,
    };
  }

  factory UserModel.fromFirestore(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return UserModel(
      uid: documentId,
      name: profileName(json),
      email: json['email'] ?? '',
      phone_number: profilePhone(json),
      roles: json['roles'] ?? 'seeker',
      verification_status: accountStatus(json),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone_number': phone_number,
      'roles': roles,
      'verification_status': verification_status,
    };
  }
}
