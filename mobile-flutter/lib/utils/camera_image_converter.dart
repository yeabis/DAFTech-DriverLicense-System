import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class CameraMetadata {
  final int sensorOrientation;
  final bool isFrontCamera;

  const CameraMetadata({
    required this.sensorOrientation,
    this.isFrontCamera = false,
  });
}

class FramePlane {
  final Uint8List bytes;
  final int bytesPerRow;
  final int? height;
  final int? width;

  const FramePlane({
    required this.bytes,
    required this.bytesPerRow,
    this.height,
    this.width,
  });
}

class CameraImageConverter {
  static InputImage? fromRawPlanes({
    required int width,
    required int height,
    required List<FramePlane> planes,
    required CameraMetadata camera,
    TargetPlatform? platform,
  }) {
    final targetPlatform = platform ?? defaultTargetPlatform;

    InputImageRotation? rotation;
    if (targetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else if (targetPlatform == TargetPlatform.android) {
      var rotationCompensation = camera.sensorOrientation;
      if (camera.isFrontCamera) {
        rotationCompensation = (camera.sensorOrientation + 360) % 360;
      } else {
        rotationCompensation = (camera.sensorOrientation + 270) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    if (planes.length == 1) {
      final plane = planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }

    if (planes.length >= 3) {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: planes.first.bytesPerRow,
        ),
      );
    }

    return null;
  }
}
