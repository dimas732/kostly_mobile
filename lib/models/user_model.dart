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

  factory UserModel.fromFirestore(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return UserModel(
      uid: documentId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone_number: json['phone_number'] ?? '',
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
