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

enum _Field { name, id, dob, expiry, registeredBy, created, type }

class _LabelMatch {
  final _Field field;
  final String rest;
  const _LabelMatch(this.field, this.rest);
}

class LicenseParser {
  static const Set<String> _ignoredHeaders = {
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
  };

  static const Set<String> _nameStopWords = {
    'NAME',
    'FULL',
    'DATE',
    'BIRTH',
    'EXPIRY',
    'EXPIRES',
    'EXPIRATION',
    'ISSUE',
    'ISSUED',
    'LICENSE',
    'LICENCE',
    'TYPE',
    'GRADE',
    'CATEGORY',
    'SEX',
    'GENDER',
    'NATIONALITY',
    'ADDRESS',
    'BLOOD',
    'GROUP',
    'NUMBER',
    'DOB',
    'REGION',
    'CITY',
    'PHONE',
    'SIGNATURE',
    'HOLDER',
    'VALID',
    'UNTIL',
    'OFFICER',
    'REGISTERED',
    'CLASS',
    'RESTRICTIONS',
    'ENDORSEMENTS',
  };

  static final RegExp _dateRegex =
      RegExp(r'\b(\d{1,4}[-/\.]\d{1,2}[-/\.]\d{1,4})\b');

  static final RegExp _dateLikeRegex = RegExp(
    r'\b([0-9OoIlSB]{1,4})\s?([-/.])\s?([0-9OoIlSB]{1,2})\s?([-/.])\s?([0-9OoIlSB]{2,4})\b',
  );

  static final RegExp _idRegex = RegExp(
    r'\b([A-Z]{1,5}[- ]?\d{3,12}|\d{5,12})\b',
    caseSensitive: false,
  );

  static final List<MapEntry<_Field, RegExp>> _labelAnchors = [
    MapEntry(
      _Field.name,
      RegExp(r'^(?:Full\s*Name|Driver\s*Name|Name)\b[\s:.\-]*(.*)$',
          caseSensitive: false),
    ),
    MapEntry(
      _Field.id,
      RegExp(
          r'^(?:License\s*ID(?:\s*Number)?|Licen[sc]e\s*(?:No|Number)|ID\s*(?:Number|No)|DL\s*(?:No|Number)|Document\s*No)\b[\s:.\-#]*(.*)$',
          caseSensitive: false),
    ),
    MapEntry(
      _Field.dob,
      RegExp(r'^(?:Date\s*of\s*Birth|Birth\s*Date|DOB)\b[\s:.\-]*(.*)$',
          caseSensitive: false),
    ),
    MapEntry(
      _Field.expiry,
      RegExp(
          r'^(?:Expiry\s*Date|Expiration\s*Date|Date\s*of\s*Expiry|Exp(?:ires)?\.?\s*Date|Valid\s*(?:Until|Till|To)|Expires|Expiry)\b[\s:.\-]*(.*)$',
          caseSensitive: false),
    ),
    MapEntry(
      _Field.registeredBy,
      RegExp(r'^(?:Registered\s*by(?:\s*user)?|Issued\s*by|Officer)\b[\s:.\-]*(.*)$',
          caseSensitive: false),
    ),
    MapEntry(
      _Field.created,
      RegExp(
          r'^(?:Issue\s*Date|Date\s*of\s*Issue|Issued(?:\s*On)?|Created\s*Date)\b[\s:.\-]*(.*)$',
          caseSensitive: false),
    ),
    MapEntry(
      _Field.type,
      RegExp(
          r'^(?:Licen[sc]e\s*Type|Licen[sc]e\s*Grade|Category|Grade|Gerad)\b[\s:.\-]*(.*)$',
          caseSensitive: false),
    ),
  ];

  static ParsedLicenseData parseOcrLines(List<String> rawLines) {
    final cleanLines = rawLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !_isDocumentHeader(l))
        .map(_normalizeDates)
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

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final next = i + 1 < lines.length ? lines[i + 1] : null;
      final label = _matchLabel(line);

      if (label != null) {
        switch (label.field) {
          case _Field.name:
            fullName ??=
                _pick(label.rest, next, (t) => _nameFrom(t, minWords: 1));
            break;
          case _Field.id:
            licenseId ??= _pick(label.rest, next, _cleanId);
            break;
          case _Field.dob:
            dob ??= _pick(label.rest, next, _extractDate);
            break;
          case _Field.expiry:
            expiryDate ??= _pick(label.rest, next, _extractDate);
            break;
          case _Field.created:
            createdDate ??= _pick(label.rest, next, _extractDate);
            break;
          case _Field.type:
            licenseType ??=
                _pick(label.rest, next, (t) => _cleanSimple(t, minLength: 1));
            break;
          case _Field.registeredBy:
            registeredBy ??=
                _pick(label.rest, next, (t) => _cleanSimple(t, minLength: 2));
            break;
        }
        continue;
      }

      if (licenseId == null && !_dateRegex.hasMatch(line)) {
        final m = _idRegex.firstMatch(line);
        if (m != null) licenseId = _cleanId(m.group(0));
      }
    }

    if (dob == null || expiryDate == null) {
      final assigned = <String>{
        if (dob != null) dob,
        if (expiryDate != null) expiryDate,
        if (createdDate != null) createdDate,
      };

      final List<String> allExtractedDates = [];
      for (final l in lines) {
        for (final m in _dateRegex.allMatches(l)) {
          final d = m.group(0);
          if (d != null &&
              !assigned.contains(d) &&
              !allExtractedDates.contains(d)) {
            allExtractedDates.add(d);
          }
        }
      }

      final remaining = allExtractedDates
          .map((dStr) => _DateEntry(dStr, _tryParseDate(dStr)))
          .where((entry) => entry.parsed != null)
          .toList()
        ..sort((a, b) => a.parsed!.compareTo(b.parsed!));

      if (dob == null && remaining.isNotEmpty) {
        dob = remaining.removeAt(0).raw;
      }
      if (expiryDate == null && remaining.isNotEmpty) {
        expiryDate = remaining.removeLast().raw;
      }
      if (createdDate == null && remaining.isNotEmpty) {
        createdDate = remaining.first.raw;
      }
    }

    if (fullName == null) {
      for (final l in lines) {
        if (l == licenseId || _isLabelLine(l) || _dateRegex.hasMatch(l)) {
          continue;
        }
        if (l.length < 5 || l.length > 40 || RegExp(r'\d').hasMatch(l)) {
          continue;
        }
        final candidate = _nameFrom(l, minWords: 2);
        if (candidate != null) {
          fullName = candidate;
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

  static bool verifyConsistency(ParsedLicenseData front, ParsedLicenseData back) {
    if (front.licenseId != null && back.licenseId != null) {
      final cOcr = front.licenseId!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      final cQr = back.licenseId!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      return cOcr == cQr || cOcr.contains(cQr) || cQr.contains(cOcr);
    }
    return true;
  }

  static String _stripLeadingJunk(String s) =>
      s.replaceFirst(RegExp(r'^[^A-Za-z0-9]+'), '');

  static _LabelMatch? _matchLabel(String line) {
    final stripped = _stripLeadingJunk(line);
    for (final entry in _labelAnchors) {
      final m = entry.value.firstMatch(stripped);
      if (m != null) return _LabelMatch(entry.key, (m.group(1) ?? '').trim());
    }
    return null;
  }

  static bool _isLabelLine(String line) => _matchLabel(line) != null;

  static String? _pick(
    String rest,
    String? next,
    String? Function(String?) clean,
  ) {
    final same = clean(rest);
    if (same != null) return same;
    if (next != null && !_isLabelLine(next)) return clean(next);
    return null;
  }

  static bool _isDocumentHeader(String line) {
    if (_isLabelLine(line)) return false;

    final tokens = line
        .toUpperCase()
        .split(RegExp(r'[^A-Z]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return false;

    final matches = tokens.where(_ignoredHeaders.contains).length;
    final hasCore = tokens.any(
      (t) => t == 'LICENSE' || t == 'LICENCE' || t == 'REPUBLIC',
    );
    return matches >= 2 || (matches >= 1 && hasCore && tokens.length <= 3);
  }

  static String _fixDigits(String s) {
    const map = {'O': '0', 'o': '0', 'I': '1', 'l': '1', 'S': '5', 'B': '8'};
    final buffer = StringBuffer();
    for (final ch in s.split('')) {
      buffer.write(map[ch] ?? ch);
    }
    return buffer.toString();
  }

  static String _digitsToLetters(String s) {
    const map = {'0': 'O', '1': 'I', '5': 'S', '8': 'B'};
    final buffer = StringBuffer();
    for (final ch in s.split('')) {
      buffer.write(map[ch] ?? ch);
    }
    return buffer.toString().replaceAll(RegExp(r'[0-9]'), '');
  }

  static String _normalizeDates(String line) {
    return line.replaceAllMapped(_dateLikeRegex, (m) {
      final fixed = '${_fixDigits(m.group(1)!)}${m.group(2)}'
          '${_fixDigits(m.group(3)!)}${m.group(4)}'
          '${_fixDigits(m.group(5)!)}';
      return _tryParseDate(fixed) != null ? fixed : m.group(0)!;
    });
  }

  static String? _extractDate(String? text) {
    if (text == null) return null;
    for (final m in _dateRegex.allMatches(text)) {
      final d = m.group(0);
      if (d != null && _tryParseDate(d) != null) return d;
    }
    return null;
  }

  static String? _cleanName(String? raw) {
    if (raw == null) return null;

    final cleaned = raw.replaceAll(RegExp(r"[^A-Za-z0-9\s'.\-]"), ' ');
    final tokens = <String>[];

    for (final rawToken in cleaned.split(RegExp(r'\s+'))) {
      var token = rawToken.replaceAll(RegExp(r"^[.\-']+|[\-']+$"), '');
      if (token.isEmpty) continue;

      final letters = RegExp(r'[A-Za-z]').allMatches(token).length;
      final digits = RegExp(r'[0-9]').allMatches(token).length;
      if (digits > 0) {
        if (letters <= digits) continue;
        token = _digitsToLetters(token);
      }

      final letterCount = RegExp(r'[A-Za-z]').allMatches(token).length;
      if (letterCount == 0) continue;
      if (letterCount == 1 && !RegExp(r'^[A-Z]\.?$').hasMatch(token)) continue;

      tokens.add(token);
    }

    if (tokens.isEmpty) return null;
    return tokens.join(' ');
  }

  static bool _isPlausibleName(String? name, {required int minWords}) {
    if (name == null) return false;

    final words = name.split(' ');
    final realWords = words
        .where((w) => RegExp(r'[A-Za-z]').allMatches(w).length >= 2)
        .length;
    if (realWords < minWords) return false;

    for (final w in words) {
      final key = w.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
      if (_nameStopWords.contains(key)) return false;
    }
    return true;
  }

  static String? _nameFrom(String? text, {required int minWords}) {
    final cleaned = _cleanName(text);
    return _isPlausibleName(cleaned, minWords: minWords) ? cleaned : null;
  }

  static String? _cleanId(String? raw) {
    if (raw == null) return null;

    final s = raw
        .replaceAll(RegExp(r'[^A-Za-z0-9\-/\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (s.length < 3 || _dateRegex.hasMatch(s)) return null;

    final m = RegExp(r'^([A-Za-z]{0,5})([-\s]?)([0-9OoIlSB]{3,12})$')
        .firstMatch(s);
    if (m != null) {
      return '${m.group(1)!.toUpperCase()}${m.group(2)}${_fixDigits(m.group(3)!)}';
    }

    if (RegExp(r'\d').allMatches(s).length < 3) return null;
    return s.toUpperCase();
  }

  static String? _cleanSimple(String? raw, {required int minLength}) {
    if (raw == null) return null;

    final s = raw
        .replaceAll(RegExp(r'[^A-Za-z0-9\s.\-/]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (s.length < minLength || s.length > 30) return null;
    return s;
  }

  static DateTime? _tryParseDate(String raw) {
    try {
      final parts = raw.split(RegExp(r'[-/\.]'));
      if (parts.length != 3) return null;

      int year;
      int month;
      int day;
      if (parts[0].length == 4) {
        year = int.parse(parts[0]);
        month = int.parse(parts[1]);
        day = int.parse(parts[2]);
      } else if (parts[2].length == 4) {
        year = int.parse(parts[2]);
        month = int.parse(parts[1]);
        day = int.parse(parts[0]);
      } else {
        return null;
      }

      if (year < 1900 || year > 2100) return null;
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }
}

class _DateEntry {
  final String raw;
  final DateTime? parsed;
  _DateEntry(this.raw, this.parsed);
}
