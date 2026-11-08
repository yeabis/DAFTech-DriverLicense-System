import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import '../models/verification_log_model.dart';
import '../models/verification_result_model.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class LoginResult {
  final String token;
  final String username;

  const LoginResult({required this.token, required this.username});
}

class RegisterResult {
  final bool alreadyRegistered;
  final String message;
  final String? licenseId;
  final String? fullName;
  final String? licenseStatus;
  final String? expiryDate;

  const RegisterResult({
    required this.alreadyRegistered,
    required this.message,
    this.licenseId,
    this.fullName,
    this.licenseStatus,
    this.expiryDate,
  });
}

class ApiService {
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.baseUrl))
          .timeout(const Duration(seconds: 4));
      return response.statusCode > 0;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<http.Response> _send(
    Future<http.Response> Function() request, {
    bool sessionAware = true,
  }) async {
    try {
      final response = await request().timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 401 && sessionAware) {
        await AuthService.logout();
        throw const ApiException(
          'Your session has expired. Please log in again.',
          statusCode: 401,
        );
      }
      return response;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Check your connection and try again.',
      );
    } on SocketException {
      throw const ApiException(
        'Cannot reach the server. Check that the backend is running and that '
        'the address in api_constants.dart is correct.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Cannot reach the server. Check that the backend is running and that '
        'the address in api_constants.dart is correct.',
      );
    }
  }

  static String _errorMessage(http.Response response, String fallback) {
    try {
      final body = json.decode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'];
        if (message is String && message.isNotEmpty) return message;

        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        if (errors is List && errors.isNotEmpty) return errors.first.toString();

        final title = body['title'];
        if (title is String && title.isNotEmpty) return title;
      }
    } catch (_) {
    }
    return fallback;
  }

  static Future<LoginResult> login(String username, String password) async {
    final response = await _send(
      () async => http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: await _headers(auth: false),
        body: json.encode({'username': username, 'password': password}),
      ),
      sessionAware: false,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final token = data['token']?.toString() ?? '';
      if (token.isEmpty) {
        throw const ApiException('The server did not return a login token.');
      }
      return LoginResult(
        token: token,
        username: data['username']?.toString() ?? username,
      );
    }

    throw ApiException(
      _errorMessage(response, 'Login failed. Please try again.'),
      statusCode: response.statusCode,
    );
  }

  static Future<VerificationResult> verifyLicense({
    required String licenseId,
    String? fullName,
    String? dob,
    String? expiryDate,
  }) async {
    final body = <String, dynamic>{
      'licenseId': licenseId,
      if (fullName != null && fullName.trim().isNotEmpty)
        'fullName': fullName.trim(),
      if (dob != null && dob.trim().isNotEmpty) 'dateOfBirth': dob.trim(),
      if (expiryDate != null && expiryDate.trim().isNotEmpty)
        'expiryDate': expiryDate.trim(),
    };

    final response = await _send(
      () async => http.post(
        Uri.parse(ApiConstants.verifyEndpoint),
        headers: await _headers(),
        body: json.encode(body),
      ),
    );

    if (response.statusCode == 200) {
      return VerificationResult.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException(
      _errorMessage(response, 'Verification failed. Please try again.'),
      statusCode: response.statusCode,
    );
  }

  static Future<List<VerificationLog>> fetchLogs() async {
    final response = await _send(
      () async => http.get(
        Uri.parse(ApiConstants.logsEndpoint),
        headers: await _headers(),
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(VerificationLog.fromJson)
            .toList();
      }
      return const [];
    }

    throw ApiException(
      _errorMessage(response, 'Could not load the scan logs.'),
      statusCode: response.statusCode,
    );
  }

  static Future<RegisterResult> registerDriver({
    required String licenseId,
    required String fullName,
    required String dob,
    required String expiryDate,
    String? licenseType,
    String? qrRawData,
    String? ocrRawText,
  }) async {
    final response = await _send(
      () async => http.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: await _headers(),
        body: json.encode({
          'licenseId': licenseId,
          'fullName': fullName,
          'dateOfBirth': dob,
          'expiryDate': expiryDate,
          'licenseType': licenseType,
          'qrRawData': qrRawData ?? '',
          'ocrRawText': ocrRawText ?? '',
        }),
      ),
    );

    if (response.statusCode == 201 ||
        response.statusCode == 200 ||
        response.statusCode == 409) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final driver = data['driver'];
      final driverMap = driver is Map<String, dynamic> ? driver : null;

      return RegisterResult(
        alreadyRegistered: response.statusCode == 409,
        message: data['message']?.toString() ?? '',
        licenseId: driverMap?['licenseId']?.toString(),
        fullName: driverMap?['fullName']?.toString(),
        licenseStatus: driverMap?['status']?.toString(),
        expiryDate: driverMap?['expiryDate']?.toString(),
      );
    }

    throw ApiException(
      _errorMessage(response, 'Could not register the driver.'),
      statusCode: response.statusCode,
    );
  }
}
