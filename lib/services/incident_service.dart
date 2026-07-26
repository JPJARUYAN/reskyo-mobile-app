import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/incident_model.dart';
import '../utils/constants.dart';

class IncidentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<IncidentModel?> createIncident({
    required IncidentType type,
    required String description,
    required double latitude,
    required double longitude,
    String? address,
    required String reporterId,
    String? barangay,
    File? photoFile,
  }) async {
    try {
      String? photoUrl;
      if (photoFile != null) {
        photoUrl = await uploadPhoto(photoFile, reporterId);
      }

      final now = DateTime.now();
      final incidentData = {
        'type': type.name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'reporter_id': reporterId,
        'status': IncidentStatus.reported.name,
        'photo_url': photoUrl,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'barangay': barangay,
      };

      final response =
          await _client.from('incidents').insert(incidentData).select().single();

      return IncidentModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<IncidentModel>> getIncidents({
    IncidentStatus? status,
    String? reporterId,
    String? barangay,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      PostgrestFilterBuilder query = _client.from('incidents').select();

      if (status != null) {
        query = query.eq('status', status.name);
      }
      if (reporterId != null) {
        query = query.eq('reporter_id', reporterId);
      }
      if (barangay != null) {
        query = query.eq('barangay', barangay);
      }

      final PostgrestTransformBuilder transform = query.order('created_at', ascending: false);
      final response = await transform.range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => IncidentModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<IncidentModel?> getIncident(String incidentId) async {
    try {
      final response = await _client
          .from('incidents')
          .select()
          .eq('id', incidentId)
          .single();

      return IncidentModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateIncidentStatus(
      String incidentId, IncidentStatus status,
      {String? verifiedBy}) async {
    try {
      final updateData = {
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (verifiedBy != null) {
        updateData['verified_by'] = verifiedBy;
      }

      await _client.from('incidents').update(updateData).eq('id', incidentId);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadPhoto(File file, String reporterId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'incidents/$reporterId/$timestamp.jpg';

      await _client.storage.from('incident-photos').upload(path, file);

      final url =
          _client.storage.from('incident-photos').getPublicUrl(path);

      return url;
    } catch (e) {
      return null;
    }
  }

  Stream<List<IncidentModel>> subscribeToIncidents() {
    return _client
        .from('incidents')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .map((list) =>
            list.map((json) => IncidentModel.fromJson(json)).toList());
  }

  Future<List<IncidentModel>> getNearbyIncidents({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final response = await _client.rpc('get_nearby_incidents', params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'radius_km': radiusKm,
      });

      return (response as List)
          .map((json) => IncidentModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
