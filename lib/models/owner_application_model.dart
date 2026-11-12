import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerApplication {
  final String applicationId;
  final String userId;
  final String fullName;
  final String nik;
  final String phoneNumber;
  final String kosName;          // Tambahan: Nama Kos
  final String kosLocation;      // Tambahan: Alamat / Lokasi Kos
  final String ktpImageUrl;
  final String propertyProofUrl; // Bukti Kepemilikan (PBB/Sertifikat/Surat Kuasa)
  final String propertyImageUrl; // Tambahan: Foto Tampak Depan/Kamar Kos
  final String status;           // 'pending', 'verified', 'rejected'
  final String rejectionReason;
  final Timestamp submittedAt;

  OwnerApplication({
    required this.applicationId,
    required this.userId,
    required this.fullName,
    required this.nik,
    required this.phoneNumber,
    required this.kosName,
    required this.kosLocation,
    required this.ktpImageUrl,
    required this.propertyProofUrl,
    required this.propertyImageUrl,
    required this.status,
    required this.rejectionReason,
    required this.submittedAt,
  });

  factory OwnerApplication.fromMap(Map<String, dynamic> map, String docId) {
    return OwnerApplication(
      applicationId: docId,
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      nik: map['nik'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      kosName: map['kosName'] ?? '',
      kosLocation: map['kosLocation'] ?? '',
      ktpImageUrl: map['ktpImageUrl'] ?? '',
      propertyProofUrl: map['propertyProofUrl'] ?? '',
      propertyImageUrl: map['propertyImageUrl'] ?? '',
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'] ?? '',
      submittedAt: map['submittedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'nik': nik,
      'phoneNumber': phoneNumber,
      'kosName': kosName,
      'kosLocation': kosLocation,
      'ktpImageUrl': ktpImageUrl,
      'propertyProofUrl': propertyProofUrl,
      'propertyImageUrl': propertyImageUrl,
      'status': status,
      'rejectionReason': rejectionReason,
      'submittedAt': submittedAt,
    };
  }
}