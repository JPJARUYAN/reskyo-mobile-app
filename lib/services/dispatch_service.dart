import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/dispatch_model.dart';
import '../models/sms_log_model.dart';
import '../utils/constants.dart';

class DispatchService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<DispatchModel?> createDispatch({
    required String incidentId,
    required String responderId,
  }) async {
    try {
      final now = DateTime.now();
      final dispatchData = {
        'incident_id': incidentId,
        'responder_id': responderId,
        'status': DispatchStatus.pending.name,
        'dispatched_at': now.toIso8601String(),
      };

      final response = await _client
          .from('dispatches')
          .insert(dispatchData)
          .select()
          .single();

      return DispatchModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDispatchStatus(
      String dispatchId, DispatchStatus status) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };

      final now = DateTime.now();
      switch (status) {
        case DispatchStatus.accepted:
          updateData['accepted_at'] = now.toIso8601String();
          break;
        case DispatchStatus.enRoute:
          updateData['en_route_at'] = now.toIso8601String();
          break;
        case DispatchStatus.onScene:
          updateData['arrived_at'] = now.toIso8601String();
          break;
        case DispatchStatus.resolved:
          updateData['resolved_at'] = now.toIso8601String();
          break;
        case DispatchStatus.pending:
          break;
      }

      await _client
          .from('dispatches')
          .update(updateData)
          .eq('id', dispatchId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DispatchModel>> getDispatchesForResponder(
      String responderId) async {
    try {
      final response = await _client
          .from('dispatches')
          .select()
          .eq('responder_id', responderId)
          .order('dispatched_at', ascending: false);

      return (response as List)
          .map((json) => DispatchModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DispatchModel>> getDispatchesForIncident(
      String incidentId) async {
    try {
      final response = await _client
          .from('dispatches')
          .select()
          .eq('incident_id', incidentId)
          .order('dispatched_at', ascending: false);

      return (response as List)
          .map((json) => DispatchModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<DispatchModel?> getActiveDispatchForResponder(
      String responderId) async {
    try {
      final response = await _client
          .from('dispatches')
          .select()
          .eq('responder_id', responderId)
          .inFilter('status', [
            DispatchStatus.pending.name,
            DispatchStatus.accepted.name,
            DispatchStatus.enRoute.name,
            DispatchStatus.onScene.name,
          ])
          .order('dispatched_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? DispatchModel.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  Stream<DispatchModel?> subscribeToResponderDispatches(String responderId) {
    return _client
        .from('dispatches')
        .stream(primaryKey: ['id'])
        .eq('responder_id', responderId)
        .order('dispatched_at', ascending: false)
        .map((list) {
      if (list.isEmpty) return null;
      return DispatchModel.fromJson(list.first);
    });
  }

  Stream<List<DispatchModel>> subscribeToIncidentDispatches(String incidentId) {
    return _client
        .from('dispatches')
        .stream(primaryKey: ['id'])
        .eq('incident_id', incidentId)
        .order('dispatched_at', ascending: false)
        .map((list) =>
            list.map((json) => DispatchModel.fromJson(json)).toList());
  }

  Future<void> matchRespondersForIncident(String incidentId) async {
    await _client.rpc('match_responders', params: {
      'incident_id': incidentId,
    });
  }

  Future<bool> sendSmsAlert({
    required String dispatchId,
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final now = DateTime.now();
      final smsLog = {
        'dispatch_id': dispatchId,
        'phone_number': phoneNumber,
        'message': message,
        'status': 'sent',
        'sent_at': now.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(SupabaseConfig.smsGatewayUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.smsGatewayApiKey}',
        },
        body: jsonEncode({
          'to': phoneNumber,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        smsLog['status'] = 'sent';
      } else {
        smsLog['status'] = 'failed';
        smsLog['error_message'] = response.body;
      }

      await _client.from('sms_logs').insert(smsLog);
      return response.statusCode == 200;
    } catch (e) {
      final smsLog = {
        'dispatch_id': dispatchId,
        'phone_number': phoneNumber,
        'message': message,
        'status': 'failed',
        'sent_at': DateTime.now().toIso8601String(),
        'error_message': e.toString(),
      };
      await _client.from('sms_logs').insert(smsLog);
      return false;
    }
  }

  Future<List<SmsLogModel>> getSmsLogs(String dispatchId) async {
    try {
      final response = await _client
          .from('sms_logs')
          .select()
          .eq('dispatch_id', dispatchId)
          .order('sent_at', ascending: false);

      return (response as List)
          .map((json) => SmsLogModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
