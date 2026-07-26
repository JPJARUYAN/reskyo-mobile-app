import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFD32F2F);
  static const Color primaryDark = Color(0xFFB71C1C);
  static const Color primaryLight = Color(0xFFFFCDD2);
  static const Color accent = Color(0xFFFF6F00);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);
}

enum UserRole { resident, responder, admin }

enum IncidentType {
  vehicularAccident,
  medicalEmergency,
  fire,
  rescueOperation,
  other,
}

extension IncidentTypeExtension on IncidentType {
  String get label {
    switch (this) {
      case IncidentType.vehicularAccident:
        return 'Vehicular Accident';
      case IncidentType.medicalEmergency:
        return 'Medical Emergency';
      case IncidentType.fire:
        return 'Fire';
      case IncidentType.rescueOperation:
        return 'Rescue Operation';
      case IncidentType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case IncidentType.vehicularAccident:
        return Icons.directions_car;
      case IncidentType.medicalEmergency:
        return Icons.local_hospital;
      case IncidentType.fire:
        return Icons.local_fire_department;
      case IncidentType.rescueOperation:
        return Icons.emergency;
      case IncidentType.other:
        return Icons.warning_amber;
    }
  }

  Color get color {
    switch (this) {
      case IncidentType.vehicularAccident:
        return Colors.orange;
      case IncidentType.medicalEmergency:
        return Colors.red;
      case IncidentType.fire:
        return Colors.deepOrange;
      case IncidentType.rescueOperation:
        return Colors.blue;
      case IncidentType.other:
        return Colors.grey;
    }
  }
}

enum IncidentStatus {
  reported,
  verified,
  dispatched,
  inProgress,
  resolved,
  dismissed,
}

extension IncidentStatusExtension on IncidentStatus {
  String get label {
    switch (this) {
      case IncidentStatus.reported:
        return 'Reported';
      case IncidentStatus.verified:
        return 'Verified';
      case IncidentStatus.dispatched:
        return 'Dispatched';
      case IncidentStatus.inProgress:
        return 'In Progress';
      case IncidentStatus.resolved:
        return 'Resolved';
      case IncidentStatus.dismissed:
        return 'Dismissed';
    }
  }

  Color get color {
    switch (this) {
      case IncidentStatus.reported:
        return Colors.orange;
      case IncidentStatus.verified:
        return Colors.blue;
      case IncidentStatus.dispatched:
        return Colors.purple;
      case IncidentStatus.inProgress:
        return Colors.teal;
      case IncidentStatus.resolved:
        return Colors.green;
      case IncidentStatus.dismissed:
        return Colors.grey;
    }
  }
}

enum DispatchStatus {
  pending,
  accepted,
  enRoute,
  onScene,
  resolved,
}

extension DispatchStatusExtension on DispatchStatus {
  String get label {
    switch (this) {
      case DispatchStatus.pending:
        return 'Pending';
      case DispatchStatus.accepted:
        return 'Accepted';
      case DispatchStatus.enRoute:
        return 'En Route';
      case DispatchStatus.onScene:
        return 'On Scene';
      case DispatchStatus.resolved:
        return 'Resolved';
    }
  }

  Color get color {
    switch (this) {
      case DispatchStatus.pending:
        return Colors.orange;
      case DispatchStatus.accepted:
        return Colors.blue;
      case DispatchStatus.enRoute:
        return Colors.purple;
      case DispatchStatus.onScene:
        return Colors.teal;
      case DispatchStatus.resolved:
        return Colors.green;
    }
  }
}

enum ResponderStatus { available, busy, offline }

class AppConstants {
  static const String appName = 'RESKYO';
  static const String appTagline =
      'GPS-Based Emergency Incident Reporting & Volunteer Responder Dispatch';
  static const String digosCity = 'Digos City';
  static const double defaultLat = 6.7569;
  static const double defaultLng = 125.3469;
  static const double defaultZoom = 14.0;
  static const int maxPhotoWidth = 1024;
  static const int maxPhotoHeight = 1024;
  static const int photoQuality = 85;

  static List<String> get incidentTypeLabels =>
      IncidentType.values.map((e) => e.label).toList();
}
