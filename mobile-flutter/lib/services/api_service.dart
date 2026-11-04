import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import '../models/driver_model.dart';

class ApiService {
  static Future<Driver?> verifyLicense(String licenseId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.verifyEndpoint}/$licenseId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Driver.fromJson(data);
      }
    } catch (_) {
    }
    return null;
  }

  static Future<bool> registerDriver(Driver driver) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(driver.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

