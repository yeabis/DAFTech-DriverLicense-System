import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/image_preprocessor.dart';
import '../utils/license_parser.dart';

class TesseractOcrService {
  final TextRecognizer _mlKitRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<ParsedLicenseData> scanFrontLicense(File rawPhotoFile) async {
    final results = <ParsedLicenseData>[];
    final lastErrors = <Object>[];

    for (final mode in OcrImageMode.values) {
      File? preparedFile;
      try {
        preparedFile = await ImagePreprocessor.prepareForOcr(
          rawPhotoFile,
          mode: mode,
        );
        final lines = await _recognizeLines(preparedFile.path);
        debugPrint('[OCR:${mode.name}] ${lines.length} lines: $lines');
        results.add(LicenseParser.parseOcrLines(lines));
      } catch (e) {
        debugPrint('[OCR:${mode.name}] failed: $e');
        lastErrors.add(e);
      } finally {
        if (preparedFile != null && await preparedFile.exists()) {
          try {
            await preparedFile.delete();
          } catch (_) {}
        }
      }
    }

    if (results.isEmpty) {
      throw lastErrors.isNotEmpty
          ? lastErrors.last
          : Exception('Text recognition produced no result');
    }

    return results.reduce(_mergeResults);
  }

  Future<List<String>> _recognizeLines(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognized =
        await _mlKitRecognizer.processImage(inputImage);

    final allLines = <TextLine>[
      for (final block in recognized.blocks) ...block.lines,
    ];

    if (allLines.isEmpty) {
      return recognized.text
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    }

    allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final rows = <List<TextLine>>[];
    for (final line in allLines) {
      if (rows.isNotEmpty) {
        final row = rows.last;
        final rowCenter = row
                .map((l) => l.boundingBox.center.dy)
                .reduce((a, b) => a + b) /
            row.length;
        final tolerance = line.boundingBox.height * 0.5;
        if ((line.boundingBox.center.dy - rowCenter).abs() <= tolerance) {
          row.add(line);
          continue;
        }
      }
      rows.add([line]);
    }

    final ordered = <String>[];
    for (final row in rows) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      for (final line in row) {
        final text = line.text.trim();
        if (text.isNotEmpty) ordered.add(text);
      }
    }
    return ordered;
  }

  ParsedLicenseData _mergeResults(ParsedLicenseData a, ParsedLicenseData b) {
    final primary = _score(a) >= _score(b) ? a : b;
    final secondary = identical(primary, a) ? b : a;

    return primary.copyWith(
      fullName: _firstNonEmpty(primary.fullName, secondary.fullName),
      licenseId: _firstNonEmpty(primary.licenseId, secondary.licenseId),
      dob: _firstNonEmpty(primary.dob, secondary.dob),
      expiryDate: _firstNonEmpty(primary.expiryDate, secondary.expiryDate),
      createdDate: _firstNonEmpty(primary.createdDate, secondary.createdDate),
    );
  }

  int _score(ParsedLicenseData d) {
    int score = 0;
    if (d.fullName?.isNotEmpty ?? false) score += 2;
    if (d.licenseId?.isNotEmpty ?? false) score += 2;
    if (d.dob?.isNotEmpty ?? false) score += 1;
    if (d.expiryDate?.isNotEmpty ?? false) score += 1;
    if (d.createdDate?.isNotEmpty ?? false) score += 1;
    return score;
  }

  String? _firstNonEmpty(String? a, String? b) {
    if (a != null && a.trim().isNotEmpty) return a;
    if (b != null && b.trim().isNotEmpty) return b;
    return null;
  }

  void dispose() {
    _mlKitRecognizer.close();
  }
}