import 'package:flutter/material.dart';

class AppColors {
  // Brand palette — derived from RESKYO shield-pin logo
  static const Color primary = Color(0xFFE01D25);       // Logo red
  static const Color primaryDark = Color(0xFF011A38);    // Logo navy
  static const Color primaryLight = Color(0xFFFCE4EC);   // Red tint (card surfaces)
  static const Color navyLight = Color(0xFF1A2A4A);      // Navy tint (app bars, nav)
  static const Color navySurface = Color(0xFFE8EAF6);    // Navy very light tint

  // Accent / secondary
  static const Color accent = Color(0xFFFF6F00);         // Orange accent

  // Surfaces
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceGlass = Color(0xF0FFFFFF);   // Glassmorphic white overlay

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnDark = Colors.white;
  static const Color textOnRed = Colors.white;

  // Semantic status colors (color + icon + label — never color alone)
  static const Color success = Color(0xFF2E7D32);        // Resolved / confirmed
  static const Color warning = Color(0xFFF9A825);        // Pending / caution
  static const Color error = Color(0xFFE01D25);          // Emergency / error (matches primary)
  static const Color info = Color(0xFF1565C0);           // Informational / en-route

  // Status-specific
  static const Color statusReported = Color(0xFFF57C00);   // Orange — reported
  static const Color statusVerified = Color(0xFF1565C0);   // Blue — verified
  static const Color statusDispatched = Color(0xFF7B1FA2); // Purple — dispatched
  static const Color statusInProgress = Color(0xFF00838F); // Teal — in progress
  static const Color statusResolved = Color(0xFF2E7D32);   // Green — resolved
  static const Color statusDismissed = Color(0xFF757575);  // Grey — dismissed

  // Incident type colors
  static const Color typeAccident = Color(0xFFF57C00);     // Orange — vehicular
  static const Color typeMedical = Color(0xFFE01D25);      // Red — medical
  static const Color typeFire = Color(0xFFBF360C);         // Deep orange — fire
  static const Color typeRescue = Color(0xFF1565C0);       // Blue — rescue
  static const Color typeOther = Color(0xFF757575);        // Grey — other
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
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
        return AppColors.typeAccident;
      case IncidentType.medicalEmergency:
        return AppColors.typeMedical;
      case IncidentType.fire:
        return AppColors.typeFire;
      case IncidentType.rescueOperation:
        return AppColors.typeRescue;
      case IncidentType.other:
        return AppColors.typeOther;
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
        return AppColors.statusReported;
      case IncidentStatus.verified:
        return AppColors.statusVerified;
      case IncidentStatus.dispatched:
        return AppColors.statusDispatched;
      case IncidentStatus.inProgress:
        return AppColors.statusInProgress;
      case IncidentStatus.resolved:
        return AppColors.statusResolved;
      case IncidentStatus.dismissed:
        return AppColors.statusDismissed;
    }
  }

  IconData get icon {
    switch (this) {
      case IncidentStatus.reported:
        return Icons.report_problem;
      case IncidentStatus.verified:
        return Icons.verified;
      case IncidentStatus.dispatched:
        return Icons.send;
      case IncidentStatus.inProgress:
        return Icons.directions_run;
      case IncidentStatus.resolved:
        return Icons.check_circle;
      case IncidentStatus.dismissed:
        return Icons.cancel;
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
        return AppColors.statusReported;
      case DispatchStatus.accepted:
        return AppColors.statusVerified;
      case DispatchStatus.enRoute:
        return AppColors.statusDispatched;
      case DispatchStatus.onScene:
        return AppColors.statusInProgress;
      case DispatchStatus.resolved:
        return AppColors.statusResolved;
    }
  }

  IconData get icon {
    switch (this) {
      case DispatchStatus.pending:
        return Icons.hourglass_empty;
      case DispatchStatus.accepted:
        return Icons.check;
      case DispatchStatus.enRoute:
        return Icons.directions;
      case DispatchStatus.onScene:
        return Icons.location_on;
      case DispatchStatus.resolved:
        return Icons.check_circle;
    }
  }
}

enum ResponderStatus { available, busy, offline }

extension ResponderStatusExtension on ResponderStatus {
  String get label {
    switch (this) {
      case ResponderStatus.available:
        return 'Available';
      case ResponderStatus.busy:
        return 'Busy';
      case ResponderStatus.offline:
        return 'Offline';
    }
  }

  Color get color {
    switch (this) {
      case ResponderStatus.available:
        return AppColors.success;
      case ResponderStatus.busy:
        return AppColors.warning;
      case ResponderStatus.offline:
        return AppColors.statusDismissed;
    }
  }
}

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
