class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone_number;
  final String roles;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone_number,
    required this.roles,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> json, String documentId) {
    return UserModel(
      uid : documentId,
      name : json['name'] ?? '',
      email : json['email'] ?? '',
      phone_number: json['phone_number'] ?? '',
      roles: json['roles'] ?? 'seeker',

    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name' : name,
      'email' : email,
      'phone_number' : phone_number,
      'roles' : roles
    };
  }
}