import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../utils/camera_image_converter.dart';

typedef OnBarcodeScanned = void Function(String rawValue, BarcodeFormat format);


class LiveQrStreamScanner {
  final BarcodeScanner _barcodeScanner;
  final OnBarcodeScanned onBarcodeDetected;

  bool _isProcessingFrame = false;
  bool _isDisposed = false;
  bool _isScanningActive = true;

  LiveQrStreamScanner({
    required this.onBarcodeDetected,
    List<BarcodeFormat> supportedFormats = const [
      BarcodeFormat.qrCode,
      BarcodeFormat.pdf417,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
    ],
  }) : _barcodeScanner = BarcodeScanner(formats: supportedFormats);

  Future<void> processCameraFrame({
    required int width,
    required int height,
    required List<FramePlane> planes,
    required CameraMetadata cameraMetadata,
  }) async {
    if (!_isScanningActive || _isDisposed || _isProcessingFrame) {
      return;
    }

    _isProcessingFrame = true;

    try {
      final inputImage = CameraImageConverter.fromRawPlanes(
        width: width,
        height: height,
        planes: planes,
        camera: cameraMetadata,
      );

      if (inputImage == null) {
        return;
      }

      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty && _isScanningActive) {
        for (final barcode in barcodes) {
          final rawValue = barcode.rawValue;
          if (rawValue != null && rawValue.trim().isNotEmpty) {
            _isScanningActive = false; 
            onBarcodeDetected(rawValue.trim(), barcode.format);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('[LiveQrStreamScanner] Frame analysis error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  void resumeScanning() {
    _isScanningActive = true;
  }

  void pauseScanning() {
    _isScanningActive = false;
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _isScanningActive = false;
    await _barcodeScanner.close();
  }
}

