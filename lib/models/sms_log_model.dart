class SmsLogModel {
  final String id;
  final String dispatchId;
  final String phoneNumber;
  final String message;
  final String status;
  final DateTime sentAt;
  final String? errorMessage;

  SmsLogModel({
    required this.id,
    required this.dispatchId,
    required this.phoneNumber,
    required this.message,
    required this.status,
    required this.sentAt,
    this.errorMessage,
  });

  factory SmsLogModel.fromJson(Map<String, dynamic> json) {
    return SmsLogModel(
      id: json['id'] as String,
      dispatchId: json['dispatch_id'] as String,
      phoneNumber: json['phone_number'] as String,
      message: json['message'] as String,
      status: json['status'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dispatch_id': dispatchId,
      'phone_number': phoneNumber,
      'message': message,
      'status': status,
      'sent_at': sentAt.toIso8601String(),
      'error_message': errorMessage,
    };
  }
}
