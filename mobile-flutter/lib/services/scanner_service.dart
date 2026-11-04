import '../utils/license_parser.dart';

class ScannerService {
  static ParsedLicenseData processBarcode(String rawData) {
    return LicenseParser.parseQr(rawData);
  }

  static ParsedLicenseData processOcrLines(List<String> lines) {
    return LicenseParser.parseOcrLines(lines);
  }
}

