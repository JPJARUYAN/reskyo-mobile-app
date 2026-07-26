import '../utils/constants.dart';

class DispatchModel {
  final String id;
  final String incidentId;
  final String responderId;
  final DispatchStatus status;
  final DateTime dispatchedAt;
  final DateTime? acceptedAt;
  final DateTime? enRouteAt;
  final DateTime? arrivedAt;
  final DateTime? resolvedAt;
  final String? notes;

  DispatchModel({
    required this.id,
    required this.incidentId,
    required this.responderId,
    required this.status,
    required this.dispatchedAt,
    this.acceptedAt,
    this.enRouteAt,
    this.arrivedAt,
    this.resolvedAt,
    this.notes,
  });

  factory DispatchModel.fromJson(Map<String, dynamic> json) {
    return DispatchModel(
      id: json['id'] as String,
      incidentId: json['incident_id'] as String,
      responderId: json['responder_id'] as String,
      status: DispatchStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DispatchStatus.pending,
      ),
      dispatchedAt: DateTime.parse(json['dispatched_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      enRouteAt: json['en_route_at'] != null
          ? DateTime.parse(json['en_route_at'] as String)
          : null,
      arrivedAt: json['arrived_at'] != null
          ? DateTime.parse(json['arrived_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'incident_id': incidentId,
      'responder_id': responderId,
      'status': status.name,
      'dispatched_at': dispatchedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'en_route_at': enRouteAt?.toIso8601String(),
      'arrived_at': arrivedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  DispatchModel copyWith({
    String? id,
    String? incidentId,
    String? responderId,
    DispatchStatus? status,
    DateTime? dispatchedAt,
    DateTime? acceptedAt,
    DateTime? enRouteAt,
    DateTime? arrivedAt,
    DateTime? resolvedAt,
    String? notes,
  }) {
    return DispatchModel(
      id: id ?? this.id,
      incidentId: incidentId ?? this.incidentId,
      responderId: responderId ?? this.responderId,
      status: status ?? this.status,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      enRouteAt: enRouteAt ?? this.enRouteAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      notes: notes ?? this.notes,
    );
  }
}
