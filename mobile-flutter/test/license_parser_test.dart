import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/utils/license_parser.dart';

void main() {
  group('LicenseParser.parseOcrLines', () {
    test('reads labelled fields and keeps "License ..." label rows', () {
      final parsed = LicenseParser.parseOcrLines([
        'FEDERAL DEMOCRATIC REPUBLIC OF ETHIOPIA',
        'Driving License',
        'Full Name: ABEBE KEBEDE TESFAYE',
        'License ID Number: DL-123456',
        'Date of Birth: 12-05-1990',
        'Expiry Date: 12-05-2030',
        'License Type: Public 1',
      ]);

      expect(parsed.fullName, 'ABEBE KEBEDE TESFAYE');
      expect(parsed.licenseId, 'DL-123456');
      expect(parsed.dob, '12-05-1990');
      expect(parsed.expiryDate, '12-05-2030');
      expect(parsed.licenseType, 'Public 1');
    });

    test('repairs letters misread as digits in dates', () {
      final parsed = LicenseParser.parseOcrLines([
        'Date of Birth: 12-O5-199O',
      ]);

      expect(parsed.dob, '12-05-1990');
    });

    test('repairs digits misread as letters in names', () {
      final parsed = LicenseParser.parseOcrLines([
        'Full Name: M1KIYAS TADESSE',
      ]);

      expect(parsed.fullName, 'MIKIYAS TADESSE');
    });

    test('repairs letters misread as digits in the license number', () {
      final parsed = LicenseParser.parseOcrLines([
        'License No: DL-12O456',
      ]);

      expect(parsed.licenseId, 'DL-120456');
    });

    test('takes the value from the next line when a label stands alone', () {
      final parsed = LicenseParser.parseOcrLines([
        'Full Name',
        'ABEBE KEBEDE',
        'Date of Birth',
        '12-05-1990',
      ]);

      expect(parsed.fullName, 'ABEBE KEBEDE');
      expect(parsed.dob, '12-05-1990');
    });

    test('does not take another label row as a value', () {
      final parsed = LicenseParser.parseOcrLines([
        'Full Name',
        'Date of Birth',
        'ABEBE KEBEDE',
        '12-05-1990',
      ]);

      expect(parsed.fullName, 'ABEBE KEBEDE');
      expect(parsed.dob, '12-05-1990');
      expect(parsed.expiryDate, isNull);
    });

    test('falls back to the first plausible name when labels are unreadable', () {
      final parsed = LicenseParser.parseOcrLines([
        'FEDERAL DEMOCRATIC REPUBLIC OF ETHIOPIA',
        'ABEBE KEBEDE TESFAYE',
        'DL-123456',
        '12-05-1990',
        '12-05-2030',
      ]);

      expect(parsed.fullName, 'ABEBE KEBEDE TESFAYE');
      expect(parsed.licenseId, 'DL-123456');
      expect(parsed.dob, '12-05-1990');
      expect(parsed.expiryDate, '12-05-2030');
    });

    test('does not reuse a labelled date for another field', () {
      final parsed = LicenseParser.parseOcrLines([
        'Date of Birth',
        'Expiry Date: 12-05-2030',
      ]);

      expect(parsed.expiryDate, '12-05-2030');
      expect(parsed.dob, isNull);
    });
  });
}

