import 'package:cloud_firestore/cloud_firestore.dart';

class KosModel {
  final String id;
  final String name;
  final String address;
  final String description;
  final int rentPrice;
  final String status;
  final String type;
  final String userId;
  final DateTime? createdAt;
  final List<String> images;
  final int listrikCost;
  final int airCost;
  final int wifiCost;

  // Field baru untuk form 3 tahap, fasilitas terpisah & ketersediaan kamar
  final bool includeListrik;
  final List<String> fasilitasKamar;
  final List<String> fasilitasArea;
  final int totalKamar;
  final int kamarTersedia;
  final String? ukuranKamar;

  static const _unchanged = Object();
  final String? verificationStatus;
  final DateTime? verificationSubmittedAt;
  final DateTime? verificationUpdatedAt;
  final DateTime? verifiedAt;
  final String rejectionReason;
  final DateTime? telegramSentFor;
  final String? telegramDeliveryStatus;

  const KosModel({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.rentPrice,
    required this.status,
    required this.type,
    required this.userId,
    this.createdAt,
    this.verificationStatus,
    this.verificationSubmittedAt,
    this.verificationUpdatedAt,
    this.verifiedAt,
    this.rejectionReason = '',
    this.telegramSentFor,
    this.telegramDeliveryStatus,
    this.images = const [],
    this.listrikCost = 0,
    this.airCost = 0,
    this.wifiCost = 0,
    this.includeListrik = false,
    this.fasilitasKamar = const [],
    this.fasilitasArea = const [],
    this.totalKamar = 0,
    this.kamarTersedia = 0,
    this.ukuranKamar,
  });

  // Helper otomatis untuk dashboard pemilik kos: Total, Penuh, Tersedia
  int get kamarPenuh {
    final penuh = totalKamar - kamarTersedia;
    return penuh < 0 ? 0 : penuh;
  }

  KosModel copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    int? rentPrice,
    String? status,
    String? type,
    String? userId,
    DateTime? createdAt,
    Object? verificationStatus = _unchanged,
    Object? verificationSubmittedAt = _unchanged,
    Object? verificationUpdatedAt = _unchanged,
    Object? verifiedAt = _unchanged,
    String? rejectionReason,
    List<String>? images,
    int? listrikCost,
    int? airCost,
    int? wifiCost,
    bool? includeListrik,
    List<String>? fasilitasKamar,
    List<String>? fasilitasArea,
    int? totalKamar,
    int? kamarTersedia,
    String? ukuranKamar,
  }) {
    return KosModel(
      verificationStatus: identical(verificationStatus, _unchanged)
          ? this.verificationStatus
          : verificationStatus as String?,
      verificationSubmittedAt: identical(verificationSubmittedAt, _unchanged)
          ? this.verificationSubmittedAt
          : verificationSubmittedAt as DateTime?,
      verificationUpdatedAt: identical(verificationUpdatedAt, _unchanged)
          ? this.verificationUpdatedAt
          : verificationUpdatedAt as DateTime?,
      verifiedAt: identical(verifiedAt, _unchanged)
          ? this.verifiedAt
          : verifiedAt as DateTime?,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      telegramSentFor: telegramSentFor,
      telegramDeliveryStatus: telegramDeliveryStatus,
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      rentPrice: rentPrice ?? this.rentPrice,
      status: status ?? this.status,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
      listrikCost: listrikCost ?? this.listrikCost,
      airCost: airCost ?? this.airCost,
      wifiCost: wifiCost ?? this.wifiCost,
      includeListrik: includeListrik ?? this.includeListrik,
      fasilitasKamar: fasilitasKamar ?? this.fasilitasKamar,
      fasilitasArea: fasilitasArea ?? this.fasilitasArea,
      totalKamar: totalKamar ?? this.totalKamar,
      kamarTersedia: kamarTersedia ?? this.kamarTersedia,
      ukuranKamar: ukuranKamar ?? this.ukuranKamar,
    );
  }

  // Sesuai pemanggilan di FirestoreService: KosModel.fromFirestore(data, doc.id)
  factory KosModel.fromFirestore(Map<String, dynamic> data, String id) {
    final electrical = data['electrical_cost'] is Map
        ? Map<String, dynamic>.from(data['electrical_cost'] as Map)
        : <String, dynamic>{};

    final recurring = data['reccuring_cost'] is Map
        ? Map<String, dynamic>.from(data['reccuring_cost'] as Map)
        : (data['recurring_cost'] is Map
              ? Map<String, dynamic>.from(data['recurring_cost'] as Map)
              : <String, dynamic>{});

    int parseInt(dynamic val, [int fallback = 0]) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    List<String> parseStringList(dynamic val) {
      if (val is List) {
        return val
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const [];
    }

    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw);
      }
      return null;
    }

    return KosModel(
      verificationStatus: data['verification_status']?.toString(),
      verificationSubmittedAt: parseDate(data['verification_submitted_at']),
      verificationUpdatedAt: parseDate(data['verification_updated_at']),
      verifiedAt: parseDate(data['verified_at']),
      rejectionReason: data['rejection_reason']?.toString() ?? '',
      telegramSentFor: parseDate(data['telegram_sent_for']),
      telegramDeliveryStatus: data['telegram_delivery_status'] as String?,
      id: id,
      name: (data['name'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      rentPrice: parseInt(data['rent_price']),
      status: (data['status'] ?? 'available').toString(),
      type: (data['type'] ?? 'Campur').toString(),
      userId: (data['user_id'] ?? '').toString(),
      createdAt: parseDate(data['created_at']),
      images: parseStringList(data['images']),
      listrikCost: parseInt(electrical['listrik']),
      airCost: parseInt(recurring['air']),
      wifiCost: parseInt(recurring['wifi']),
      includeListrik: data['include_listrik'] == true,
      fasilitasKamar: parseStringList(data['fasilitas_kamar']),
      fasilitasArea: parseStringList(data['fasilitas_area']),
      totalKamar: parseInt(data['total_kamar']),
      kamarTersedia: parseInt(data['kamar_tersedia']),
      ukuranKamar: data['ukuran_kamar']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      ...propertyFields(),
      'user_id': userId,
      'created_at': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      if (verificationStatus != null) 'verification_status': verificationStatus,
      'verification_submitted_at': verificationSubmittedAt == null
          ? null
          : Timestamp.fromDate(verificationSubmittedAt!),
      'verification_updated_at': verificationUpdatedAt == null
          ? null
          : Timestamp.fromDate(verificationUpdatedAt!),
      'verified_at': verifiedAt == null
          ? null
          : Timestamp.fromDate(verifiedAt!),
      'rejection_reason': rejectionReason,
    };
  }

  Map<String, dynamic> propertyFields() {
    return {
      'name': name,
      'address': address,
      'description': description,
      'rent_price': rentPrice,
      'status': status,
      'type': type,
      'images': images,
      'electrical_cost': {'listrik': listrikCost},
      'reccuring_cost': {'air': airCost, 'wifi': wifiCost},
      'include_listrik': includeListrik,
      'fasilitas_kamar': fasilitasKamar,
      'fasilitas_area': fasilitasArea,
      'total_kamar': totalKamar,
      'kamar_tersedia': kamarTersedia,
      if (ukuranKamar != null && ukuranKamar!.trim().isNotEmpty)
        'ukuran_kamar': ukuranKamar!.trim(),
    };
  }
}
