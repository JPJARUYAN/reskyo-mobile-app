import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class RouteModel {
  final List<RoutePoint> path;
  final double distanceMeters;
  final double etaMinutes;
  final bool isFallback;

  RouteModel({
    required this.path,
    required this.distanceMeters,
    required this.etaMinutes,
    this.isFallback = false,
  });

  String get distanceText {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get etaText {
    if (etaMinutes < 1) {
      return 'Arriving now';
    }
    if (etaMinutes < 60) {
      return '${etaMinutes.round()} min';
    }
    final hours = (etaMinutes / 60).floor();
    final mins = (etaMinutes % 60).round();
    return '${hours}h ${mins}m';
  }
}

class RoutePoint {
  final double latitude;
  final double longitude;
  final String? roadName;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    this.roadName,
  });
}

class RoutingService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Compute route using A* via Supabase Edge Function
  Future<RouteModel?> computeRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'compute-route',
        body: {
          'start_lat': startLat,
          'start_lng': startLng,
          'end_lat': endLat,
          'end_lng': endLng,
        },
      );

      if (response.status != 200) return null;

      final data = response.data;
      final path = (data['path'] as List)
          .map((p) => RoutePoint(
                latitude: p['latitude'].toDouble(),
                longitude: p['longitude'].toDouble(),
                roadName: p['road_name'],
              ))
          .toList();

      return RouteModel(
        path: path,
        distanceMeters: (data['distanceMeters'] as num).toDouble(),
        etaMinutes: (data['etaMinutes'] as num).toDouble(),
        isFallback: data['fallback'] ?? false,
      );
    } catch (e) {
      return null;
    }
  }

  /// Straight-line fallback (no Edge Function needed)
  RouteModel computeStraightLine({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final distance = _haversineMeters(startLat, startLng, endLat, endLng);
    final etaMinutes = (distance / 1000 / 30) * 60;

    return RouteModel(
      path: [
        RoutePoint(latitude: startLat, longitude: startLng),
        RoutePoint(latitude: endLat, longitude: endLng),
      ],
      distanceMeters: distance,
      etaMinutes: etaMinutes,
      isFallback: true,
    );
  }

  /// Open route in Google Maps app (fallback)
  static String googleMapsUrl({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) {
    return 'https://www.google.com/maps/dir/?api=1'
        '&origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&travelmode=driving';
  }

  double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
