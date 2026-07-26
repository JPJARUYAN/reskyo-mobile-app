import '../utils/constants.dart';

class IncidentModel {
  final String id;
  final IncidentType type;
  final String description;
  final double latitude;
  final double longitude;
  final String? address;
  final String reporterId;
  final IncidentStatus status;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? verifiedBy;
  final String? barangay;
  final double? distanceKm;

  IncidentModel({
    required this.id,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.reporterId,
    required this.status,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.verifiedBy,
    this.barangay,
    this.distanceKm,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] as String,
      type: IncidentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => IncidentType.other,
      ),
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      reporterId: json['reporter_id'] as String,
      status: IncidentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => IncidentStatus.reported,
      ),
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      verifiedBy: json['verified_by'] as String?,
      barangay: json['barangay'] as String?,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'reporter_id': reporterId,
      'status': status.name,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'verified_by': verifiedBy,
      'barangay': barangay,
    };
  }

  IncidentModel copyWith({
    String? id,
    IncidentType? type,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    String? reporterId,
    IncidentStatus? status,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? verifiedBy,
    String? barangay,
    double? distanceKm,
  }) {
    return IncidentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      reporterId: reporterId ?? this.reporterId,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      barangay: barangay ?? this.barangay,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
