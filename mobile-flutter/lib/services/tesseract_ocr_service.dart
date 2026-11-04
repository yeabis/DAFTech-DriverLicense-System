import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/image_preprocessor.dart';
import '../utils/license_parser.dart';


class TesseractOcrService {
  final TextRecognizer _mlKitRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  [ParsedLicenseData].
  Future<ParsedLicenseData> scanFrontLicense(File rawPhotoFile) async {
    File? preprocessedFile;
    try {
      preprocessedFile = await ImagePreprocessor.prepareForOcr(rawPhotoFile);

      final extractedText = await _extractTextWithTesseract(preprocessedFile.path);

      final lines = extractedText
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      return LicenseParser.parseOcrLines(lines);
    } finally {
      if (preprocessedFile != null && await preprocessedFile.exists()) {
        try {
          await preprocessedFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<String> _extractTextWithTesseract(String imagePath) async {
    final Map<String, String> tesseractArgs = {
      'psm': '6',
      'preserve_interword_spaces': '1',
      'tessedit_char_whitelist':
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-/:., ',
    };

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _mlKitRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('[TesseractOcrService] Primary OCR error: $e. Falling back to ML Kit.');
      final inputImage = InputImage.fromFilePath(imagePath);
      final fallbackResult = await _mlKitRecognizer.processImage(inputImage);
      return fallbackResult.text;
    }
  }

  void dispose() {
    _mlKitRecognizer.close();
  }
}

