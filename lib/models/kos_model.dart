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
  final List<String> images;
  final Map<String, int> reccuringCost; // 🔹 Diperketat tipenya
  final Map<String, int> electricalCost; // 🔹 Diperketat tipenya
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
    required this.images,
    required this.reccuringCost,
    required this.electricalCost,
    this.createdAt,
  });

  String get image => images.isNotEmpty ? images.first : '';

  Map<String, dynamic> toMap() => toFirestore();

  factory KosModel.fromFirestore(Map<String, dynamic> json, String documentId) {
    List<String> parseImages(dynamic data) {
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      } else if (data is String && data.isNotEmpty) {
        return [data];
      }
      return [];
    }

    Map<String, int> parseMap(dynamic mapData) {
      Map<String, int> result = {};
      if (mapData is Map) {
        mapData.forEach((key, value) {
          result[key.toString()] = int.tryParse(value.toString()) ?? 0;
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
      images: parseImages(json['images'] ?? json['image']),
      reccuringCost: parseMap(json['reccuring_cost']),
      electricalCost: parseMap(json['electrical_cost']),
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'rent_price': rentPrice,
      'type': type,
      'address': address,
      'description': description,
      'status': status,
      'images': images,
      'reccuring_cost': reccuringCost,
      'electrical_cost': electricalCost,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}