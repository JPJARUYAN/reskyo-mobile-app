import '../utils/constants.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String contactNumber;
  final String barangay;
  final UserRole role;
  final DateTime createdAt;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.contactNumber,
    required this.barangay,
    required this.role,
    required this.createdAt,
    this.photoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      contactNumber: json['contact_number'] as String,
      barangay: json['barangay'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.resident,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'full_name': fullName,
      'contact_number': contactNumber,
      'barangay': barangay,
      'role': role.name,
      'created_at': createdAt.toIso8601String(),
      'photo_url': photoUrl,
    };
  }

  bool get isResident => role == UserRole.resident;
  bool get isResponder => role == UserRole.responder;
  bool get isAdmin => role == UserRole.admin;

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? contactNumber,
    String? barangay,
    UserRole? role,
    DateTime? createdAt,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      contactNumber: contactNumber ?? this.contactNumber,
      barangay: barangay ?? this.barangay,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
