class ParsedLicenseData {
  final String? fullName;
  final String? licenseId;
  final String? dob;
  final String? expiryDate;
  final String? createdDate;
  final String? licenseType;
  final String? registeredBy;
  final double confidenceScore;

  const ParsedLicenseData({
    this.fullName,
    this.licenseId,
    this.dob,
    this.expiryDate,
    this.createdDate,
    this.licenseType,
    this.registeredBy,
    this.confidenceScore = 1.0,
  });

  bool get isComplete =>
      (fullName?.isNotEmpty ?? false) && (licenseId?.isNotEmpty ?? false);

  ParsedLicenseData copyWith({
    String? fullName,
    String? licenseId,
    String? dob,
    String? expiryDate,
    String? createdDate,
    String? licenseType,
    String? registeredBy,
    double? confidenceScore,
  }) {
    return ParsedLicenseData(
      fullName: fullName ?? this.fullName,
      licenseId: licenseId ?? this.licenseId,
      dob: dob ?? this.dob,
      expiryDate: expiryDate ?? this.expiryDate,
      createdDate: createdDate ?? this.createdDate,
      licenseType: licenseType ?? this.licenseType,
      registeredBy: registeredBy ?? this.registeredBy,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'licenseId': licenseId,
      'dob': dob,
      'expiryDate': expiryDate,
      'createdDate': createdDate,
      'licenseType': licenseType,
      'registeredBy': registeredBy,
    };
  }
}

class LicenseParser {
  static final List<String> _ignoredHeaders = [
    'FEDERAL',
    'DEMOCRATIC',
    'REPUBLIC',
    'ETHIOPIA',
    'DRIVING',
    'DRIVER',
    'DRIVERS',
    'LICENSE',
    'LICENCE',
    'TRANSPORT',
    'AUTHORITY',
    'MINISTRY',
    'GOVERNMENT',
    'PERMIT',
    'NATIONAL',
    'IDENTITY',
    'CARD',
  ];

  static final RegExp _dateRegex =
      RegExp(r'\b(\d{1,4}[-/\.]\d{1,2}[-/\.]\d{1,4})\b');

  static final RegExp _idRegex = RegExp(
    r'\b(DL[- ]?\d{5,8}|ET[- ]?\d{5,8}|[A-Z]{2,3}[- ]?\d{5,8})\b',
    caseSensitive: false,
  );

  static ParsedLicenseData parseOcrLines(List<String> rawLines) {
    final cleanLines = rawLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !_isDocumentHeader(l))
        .toList();

    return _extractFields(cleanLines);
  }

  static ParsedLicenseData _extractFields(List<String> lines) {
    String? fullName;
    String? licenseId;
    String? dob;
    String? expiryDate;
    String? createdDate;
    String? licenseType;
    String? registeredBy;

    final nameAnchor =
        RegExp(r'^(?:Full\s*Name|Name|Driver\s*Name)[\s:]*(.*)$', caseSensitive: false);
    final idAnchor = RegExp(
        r'^(?:License\s*ID(?:\s*Number)?|License\s*No|ID\s*Number|ID\s*No|DL\s*No|Document\s*No)[\s:]*(.*)$',
        caseSensitive: false);
    final dobAnchor =
        RegExp(r'^(?:Date\s*of\s*Birth|DOB|Birth\s*Date)[\s:]*(.*)$', caseSensitive: false);
    final expiryAnchor = RegExp(
        r'^(?:Expiry\s*Date|Exp\s*Date|Expiration\s*Date|Valid\s*Until)[\s:]*(.*)$',
        caseSensitive: false);
    final createdAnchor = RegExp(
        r'^(?:Issue\s*Date|Created\s*Date|Date\s*of\s*Issue)[\s:]*(.*)$',
        caseSensitive: false);
    final typeAnchor = RegExp(
        r'^(?:License\s*Type|Category|Grade|Gerad)[\s:]*(.*)$',
        caseSensitive: false);
    final registeredByAnchor = RegExp(
        r'^(?:Registered\s*by(?:\s*user)?|Issued\s*by|Officer)[\s:]*(.*)$',
        caseSensitive: false);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (fullName == null && nameAnchor.hasMatch(line)) {
        final match = nameAnchor.firstMatch(line);
        final sameLineValue = match?.group(1)?.trim() ?? '';
        if (_isValidFieldValue(sameLineValue)) {
          fullName = sameLineValue;
        } else if (i + 1 < lines.length && _isValidFieldValue(lines[i + 1])) {
          fullName = lines[i + 1].trim(); 
        }
        continue;
      }

      if (licenseId == null && idAnchor.hasMatch(line)) {
        final match = idAnchor.firstMatch(line);
        final sameLineValue = match?.group(1)?.trim() ?? '';
        if (_isValidFieldValue(sameLineValue)) {
          licenseId = sameLineValue;
        } else if (i + 1 < lines.length && _isValidFieldValue(lines[i + 1])) {
          licenseId = lines[i + 1].trim(); 
        }
        continue;
      }

      if (dob == null && dobAnchor.hasMatch(line)) {
        final match = dobAnchor.firstMatch(line);
        final sameLineValue = match?.group(1)?.trim() ?? '';
        if (_dateRegex.hasMatch(sameLineValue)) {
          dob = _dateRegex.firstMatch(sameLineValue)?.group(0);
        } else if (i + 1 < lines.length && _dateRegex.hasMatch(lines[i + 1])) {
          dob = _dateRegex.firstMatch(lines[i + 1])?.group(0); // Look-ahead
        }
        continue;
      }

      if (expiryDate == null && expiryAnchor.hasMatch(line)) {
        final match = expiryAnchor.firstMatch(line);
        final sameLineValue = match?.group(1)?.trim() ?? '';
        if (_dateRegex.hasMatch(sameLineValue)) {
          expiryDate = _dateRegex.firstMatch(sameLineValue)?.group(0);
        } else if (i + 1 < lines.length && _dateRegex.hasMatch(lines[i + 1])) {
          expiryDate = _dateRegex.firstMatch(lines[i + 1])?.group(0); // Look-ahead
        }
        continue;
      }

      if (createdDate == null && createdAnchor.hasMatch(line)) {
        final match = createdAnchor.firstMatch(line);
        final sameLineValue = match?.group(1)?.trim() ?? '';
        if (_dateRegex.hasMatch(sameLineValue)) {
          createdDate = _dateRegex.firstMatch(sameLineValue)?.group(0);
        } else if (i + 1 < lines.length && _dateRegex.hasMatch(lines[i + 1])) {
          createdDate = _dateRegex.firstMatch(lines[i + 1])?.group(0); // Look-ahead
        }
        continue;
      }

      if (licenseType == null && typeAnchor.hasMatch(line)) {
        final match = typeAnchor.firstMatch(line);
        final sameLineValue = match?.group(1)?.trim() ?? '';
        if (_isValidFieldValue(sameLineValue)) {
          licenseType = sameLineValue;
        } else if (i + 1 < lines.length && _isValidFieldValue(lines[i + 1])) {
          licenseType = lines[i + 1].trim(); 
        }
        continue;
      }

      if (registeredBy == null && registeredByAnchor.hasMatch(line)) {
        final match = registeredByAnchor.firstMatch(line);
        final sameLineValue = match?.group(1)?.trim() ?? '';
        if (_isValidFieldValue(sameLineValue)) {
          registeredBy = sameLineValue;
        } else if (i + 1 < lines.length && _isValidFieldValue(lines[i + 1])) {
          registeredBy = lines[i + 1].trim(); 
        }
        continue;
      }

      if (licenseId == null && _idRegex.hasMatch(line)) {
        licenseId = _idRegex.firstMatch(line)?.group(0);
      }
    }

    if (dob == null || expiryDate == null) {
      final List<String> allExtractedDates = [];
      for (final l in lines) {
        for (final m in _dateRegex.allMatches(l)) {
          final d = m.group(0);
          if (d != null && !allExtractedDates.contains(d)) {
            allExtractedDates.add(d);
          }
        }
      }

      final parsedDates = allExtractedDates
          .map((dStr) => _DateEntry(dStr, _tryParseDate(dStr)))
          .where((entry) => entry.parsed != null)
          .toList()
        ..sort((a, b) => a.parsed!.compareTo(b.parsed!));

      if (parsedDates.isNotEmpty) {
        dob ??= parsedDates.first.raw;
        if (parsedDates.length >= 2) {
          expiryDate ??= parsedDates.last.raw;
        }
        if (parsedDates.length >= 3 && createdDate == null) {
          createdDate = parsedDates[1].raw;
        }
      }
    }

    if (fullName == null) {
      for (final l in lines) {
        if (l != licenseId &&
            !_dateRegex.hasMatch(l) &&
            l.length >= 5 &&
            l.length <= 40 &&
            l.contains(' ') &&
            !RegExp(r'\d').hasMatch(l)) {
          fullName = l;
          break;
        }
      }
    }

    return ParsedLicenseData(
      fullName: fullName,
      licenseId: licenseId,
      dob: dob,
      expiryDate: expiryDate,
      createdDate: createdDate,
      licenseType: licenseType ?? 'Public 1',
      registeredBy: registeredBy ?? 'Officer 1',
    );
  }

  static ParsedLicenseData parseQr(String rawData) {
    final clean = rawData.trim();

    if (clean.startsWith('{') && clean.endsWith('}')) {
      String? extract(String key) {
        final regex = RegExp('"$key"\\s*:\\s*"([^"]+)"', caseSensitive: false);
        return regex.firstMatch(clean)?.group(1);
      }

      return ParsedLicenseData(
        licenseId: extract('licenseId') ?? extract('id') ?? extract('dlNo'),
        fullName: extract('fullName') ?? extract('name'),
        dob: extract('dob'),
        expiryDate: extract('expiryDate') ?? extract('expiry'),
        createdDate: extract('createdDate'),
        licenseType: extract('licenseType') ?? extract('grade') ?? 'Public 1',
      );
    }

    if (clean.contains('|')) {
      final parts = clean.split('|');
      return ParsedLicenseData(
        licenseId: parts.isNotEmpty ? parts[0].trim() : null,
        fullName: parts.length > 1 ? parts[1].trim() : null,
        dob: parts.length > 2 ? parts[2].trim() : null,
        expiryDate: parts.length > 3 ? parts[3].trim() : null,
        licenseType: parts.length > 4 ? parts[4].trim() : 'Public 1',
      );
    }

    return ParsedLicenseData(
      licenseId: clean,
      fullName: null,
      licenseType: 'Public 1',
    );
  }

  static bool verifyConsistency(ParsedLicenseData frontOcr, ParsedLicenseData backQr) {
    if (frontOcr.licenseId != null && backQr.licenseId != null) {
      final cleanOcr = frontOcr.licenseId!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      final cleanQr = backQr.licenseId!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      return cleanOcr == cleanQr || cleanOcr.contains(cleanQr) || cleanQr.contains(cleanOcr);
    }
    return true;
  }

  static bool _isValidFieldValue(String text) {
    return text.trim().isNotEmpty && text.trim().length >= 2;
  }

  static bool _isDocumentHeader(String line) {
    final upper = line.toUpperCase();
    int matches = 0;
    for (final word in _ignoredHeaders) {
      if (upper.contains(word)) matches++;
    }
    return matches >= 2 || (matches >= 1 && (upper.contains('LICENSE') || upper.contains('REPUBLIC')));
  }

  static DateTime? _tryParseDate(String raw) {
    try {
      final parts = raw.split(RegExp(r'[-/\.]'));
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else if (parts[2].length == 4) {
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    } catch (_) {}
    return null;
  }
}

class _DateEntry {
  final String raw;
  final DateTime? parsed;

  _DateEntry(this.raw, this.parsed);
}
