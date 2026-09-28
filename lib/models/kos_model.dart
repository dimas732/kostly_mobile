import 'package:cloud_firestore/cloud_firestore.dart';

class KosModel {
  final String id;
  final String userId;
  final String name;
  final int rentPrice;
  final String type;
  final String address;
  final String description;
  final String status;
  final String image;
  final Map reccuringCost;
  final Map electricalCost;
  final DateTime? createdAt;

  KosModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.rentPrice,
    required this.type,
    required this.address,
    required this.description,
    required this.status,
    required this.image,
    required this.reccuringCost,
    required this.electricalCost,
    this.createdAt,
  });

  // 💡 1. toMap() langsung mengembalikan toFirestore() agar selalu sinkron
  Map<String, dynamic> toMap() {
    return toFirestore();
  }
  // 💡 2. Menggunakan Map secara eksplisit
  factory KosModel.fromFirestore(Map json, String documentId) {
    Map parseMap(dynamic mapData) {
      Map result = {};
      if (mapData is Map) {
        mapData.forEach((key, value) {
          result[key] = (value as num).toInt();
        });
      }
      return result;
    }

    return KosModel(
      id: documentId,
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      rentPrice: (json['rent_price'] ?? 0) as int,
      type: json['type'] ?? 'Putra',
      address: json['address'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'available',
      image: json['image'] ?? '',
      reccuringCost: parseMap(json['reccuring_cost']),
      electricalCost: parseMap(json['electrical_cost']),
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  // 💡 3. Konsisten menggunakan snake_case dan return Map
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'rent_price': rentPrice,
      'type': type,
      'address': address,
      'description': description,
      'status': status,
      'image': image,
      'reccuring_cost': reccuringCost,
      'electrical_cost': electricalCost,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}