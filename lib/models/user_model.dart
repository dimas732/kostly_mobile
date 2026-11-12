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
    required this.verification_status
  });

  factory UserModel.fromFirestore(Map<String, dynamic> json, String documentId) {
    return UserModel(
      uid : documentId,
      name : json['name'] ?? '',
      email : json['email'] ?? '',
      phone_number: json['phone_number'] ?? '',
      roles: json['roles'] ?? 'seeker',
      verification_status: json['verification_status'] ?? 'pending'

    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name' : name,
      'email' : email,
      'phone_number' : phone_number,
      'roles' : roles,
      'verification_status' : verification_status
    };
  }
}