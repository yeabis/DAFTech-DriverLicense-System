class ApiConstants {
  // Update this to your backend host IP or emulator loopback
  // Android emulator: 10.0.2.2:5000 / 10.0.2.2:7245
  // Physical device: your LAN IP e.g. 192.168.1.x:5000
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String verifyEndpoint = '$baseUrl/drivers/verify';
  static const String registerEndpoint = '$baseUrl/drivers/register';
  static const String logsEndpoint = '$baseUrl/logs';
}

