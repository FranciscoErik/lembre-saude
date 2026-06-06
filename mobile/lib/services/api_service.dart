import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lembre_saude_mobile/config/api_config.dart';
import 'package:lembre_saude_mobile/models/dose.dart';
import 'package:lembre_saude_mobile/models/medication.dart';
import 'package:lembre_saude_mobile/models/notification_settings.dart';
import 'package:lembre_saude_mobile/models/patient_link.dart';
import 'package:lembre_saude_mobile/models/patient_overview.dart';
import 'package:lembre_saude_mobile/models/user.dart';
import 'package:lembre_saude_mobile/services/auth_storage.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.code});

  final int statusCode;
  final String message;
  final String? code;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  ApiService({AuthStorage? authStorage})
      : baseUrl = ApiConfig.baseUrl,
        authStorage = authStorage ?? AuthStorage();

  final String baseUrl;
  final AuthStorage authStorage;

  // —— Auth ——

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final data = await _post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    return AuthResponse.fromJson(data);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return AuthResponse.fromJson(data);
  }

  Future<void> saveAuth(AuthResponse auth) {
    return authStorage.saveSession(token: auth.token, user: auth.user);
  }

  // —— Users ——

  Future<AppUser> getProfile() async {
    final data = await _get('/users/me', authenticated: true);
    return AppUser.fromJson(data);
  }

  Future<bool> hasLgpdConsent() async {
    final list = await getConsents();
    return list.any((c) => (c['type'] as String?) == 'DATA_PROCESSING');
  }

  Future<List<Map<String, dynamic>>> getConsents() async {
    final data = await _getList('/users/me/consents', authenticated: true);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> grantConsent(String type) async {
    await _post(
      '/users/me/consents',
      body: {'type': type},
      authenticated: true,
    );
  }

  Future<void> deleteAccount() async {
    await _delete('/users/me', authenticated: true);
    await authStorage.clear();
  }

  // —— Medications ——

  Future<List<Medication>> getMedications() async {
    final list = await _getList('/medications', authenticated: true);
    return list.map((e) => Medication.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Medication> createMedication({
    required String name,
    required String dosage,
    required String schedule,
    required String frequency,
  }) async {
    final data = await _post(
      '/medications',
      body: {
        'name': name,
        'dosage': dosage,
        'schedule': schedule,
        'frequency': frequency,
      },
      authenticated: true,
    );
    return Medication.fromJson(data);
  }

  Future<void> deleteMedication(String id) async {
    await _delete('/medications/$id', authenticated: true);
  }

  // —— Doses ——

  Future<AdherenceSummary> getAdherence({String? from, String? to}) async {
    final query = <String, String>{};
    if (from != null) query['from'] = from;
    if (to != null) query['to'] = to;

    final data = await _get(
      '/doses/adherence',
      queryParameters: query.isEmpty ? null : query,
      authenticated: true,
    );
    return AdherenceSummary.fromJson(data);
  }

  Future<Dose> confirmDose(String doseId, {String status = 'TAKEN'}) async {
    final data = await _post(
      '/doses/$doseId/confirm',
      body: {'status': status},
      authenticated: true,
    );
    return Dose.fromJson(data);
  }

  // —— Links ——

  Future<String> createInviteCode() async {
    final data = await _post('/links/invite-code', authenticated: true);
    return data['inviteCode'] as String;
  }

  Future<AppUser> acceptInvite(String inviteCode) async {
    final data = await _post(
      '/links/accept',
      body: {'inviteCode': inviteCode},
      authenticated: true,
    );
    return AppUser.fromJson(data['patient'] as Map<String, dynamic>);
  }

  Future<List<PatientLink>> getLinkedPatients() async {
    final list = await _getList('/links/patients', authenticated: true);
    return list.map((e) => PatientLink.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PatientOverview> getPatientOverview(String patientId) async {
    final data = await _get('/links/patients/$patientId/overview', authenticated: true);
    return PatientOverview.fromJson(data);
  }

  Future<NotificationSettings> getNotificationSettings() async {
    final data = await _get('/users/me/notifications', authenticated: true);
    return NotificationSettings.fromJson(data);
  }

  Future<NotificationSettings> updateNotificationSettings({
    required bool enabled,
    int? remindBeforeMinutes,
  }) async {
    final body = <String, dynamic>{'enabled': enabled};
    if (remindBeforeMinutes != null) {
      body['remindBeforeMinutes'] = remindBeforeMinutes;
    }
    final data = await _patch('/users/me/notifications', body: body, authenticated: true);
    return NotificationSettings.fromJson(data);
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.patch(
      uri,
      headers: await _headers(authenticated),
      body: body != null ? jsonEncode(body) : null,
    );
    return _parseObject(response);
  }

  Future<bool> checkHealth() async {
    try {
      final data = await _get('/health');
      return data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  // —— HTTP ——

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
    final response = await http.get(uri, headers: await _headers(authenticated));
    return _parseObject(response);
  }

  Future<List<dynamic>> _getList(String path, {bool authenticated = false}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: await _headers(authenticated));
    return _parseList(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.post(
      uri,
      headers: await _headers(authenticated),
      body: body != null ? jsonEncode(body) : null,
    );
    return _parseObject(response);
  }

  Future<void> _delete(String path, {bool authenticated = false}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.delete(uri, headers: await _headers(authenticated));
    if (response.statusCode == 204) return;
    _parseObject(response);
  }

  Future<Map<String, String>> _headers(bool authenticated) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authenticated) {
      final token = await authStorage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _parseObject(http.Response response) {
    if (response.statusCode == 204) return {};

    final dynamic decoded =
        response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    }

    if (decoded is Map<String, dynamic>) {
      throw ApiException(
        response.statusCode,
        decoded['message'] as String? ?? 'Erro na requisição',
        code: decoded['code'] as String?,
      );
    }
    throw ApiException(response.statusCode, 'Erro ${response.statusCode}');
  }

  List<dynamic> _parseList(http.Response response) {
    final dynamic decoded =
        response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is List) return decoded;
      return [];
    }

    if (decoded is Map<String, dynamic>) {
      throw ApiException(
        response.statusCode,
        decoded['message'] as String? ?? 'Erro na requisição',
        code: decoded['code'] as String?,
      );
    }
    throw ApiException(response.statusCode, 'Erro ${response.statusCode}');
  }
}
