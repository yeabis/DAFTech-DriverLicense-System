class ApiConstants {
  static const String baseUrl = 'http://192.168.1.23:5000/api';

  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String registerEndpoint = '$baseUrl/drivers/register';
  static const String verifyEndpoint = '$baseUrl/verification/verify';
  static const String logsEndpoint = '$baseUrl/verification/logs';

  static const Duration requestTimeout = Duration(seconds: 15);
}
