import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageProcessingConfig {
  final double cardAspectRatio;
  
  final double viewportScale;

  final double contrastBoost;

  const ImageProcessingConfig({
    this.cardAspectRatio = 1.586,
    this.viewportScale = 0.85,
    this.contrastBoost = 1.6,
  });
}

class _PreprocessParams {
  final String inputPath;
  final String outputPath;
  final ImageProcessingConfig config;

  _PreprocessParams({
    required this.inputPath,
    required this.outputPath,
    required this.config,
  });
}

class ImagePreprocessor {
  static Future<File> prepareForOcr(
    File rawImageFile, {
    ImageProcessingConfig config = const ImageProcessingConfig(),
  }) async {
    final tempDir = Directory.systemTemp;
    final processedPath =
        '${tempDir.path}/ocr_preprocessed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final params = _PreprocessParams(
      inputPath: rawImageFile.path,
      outputPath: processedPath,
      config: config,
    );

    final resultPath = await compute(_preprocessWorker, params);
    return File(resultPath);
  }

  static String _preprocessWorker(_PreprocessParams params) {
    final bytes = File(params.inputPath).readAsBytesSync();
    final img.Image? decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Failed to decode image bytes at ${params.inputPath}');
    }

    final oriented = img.bakeOrientation(decoded);

    final imageWidth = oriented.width;
    final imageHeight = oriented.height;

    int cropWidth;
    int cropHeight;

    if (imageWidth > imageHeight) {
      cropWidth = (imageWidth * params.config.viewportScale).round();
      cropHeight = (cropWidth / params.config.cardAspectRatio).round();
      if (cropHeight > imageHeight) {
        cropHeight = (imageHeight * params.config.viewportScale).round();
        cropWidth = (cropHeight * params.config.cardAspectRatio).round();
      }
    } else {
      cropWidth = (imageWidth * params.config.viewportScale).round();
      cropHeight = (cropWidth / params.config.cardAspectRatio).round();
    }

    final cropX = ((imageWidth - cropWidth) / 2).clamp(0, imageWidth - 1).round();
    final cropY = ((imageHeight - cropHeight) / 2).clamp(0, imageHeight - 1).round();

    final cropped = img.copyCrop(
      oriented,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    final grayscale = img.grayscale(cropped);

    final enhanced = img.adjustColor(
      grayscale,
      contrast: params.config.contrastBoost,
      gamma: 0.9,
    );

    final processedBytes = img.encodeJpg(enhanced, quality: 95);
    final outputFile = File(params.outputPath)..writeAsBytesSync(processedBytes);

    return outputFile.path;
  }
}

