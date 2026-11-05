import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

enum OcrImageMode {
  natural,
  enhanced,
}

class ImageProcessingConfig {
  final double contrastBoost;
  final int maxLongSide;
  final int minLongSide;
  final bool cropToCard;
  final double cardAspectRatio;
  final double viewportScale;

  const ImageProcessingConfig({
    this.contrastBoost = 1.25,
    this.maxLongSide = 2400,
    this.minLongSide = 1600,
    this.cropToCard = false,
    this.cardAspectRatio = 1.586,
    this.viewportScale = 0.95,
  });
}

class _PreprocessParams {
  final String inputPath;
  final String outputPath;
  final ImageProcessingConfig config;
  final OcrImageMode mode;

  _PreprocessParams({
    required this.inputPath,
    required this.outputPath,
    required this.config,
    required this.mode,
  });
}

class ImagePreprocessor {
  static Future<File> prepareForOcr(
    File rawImageFile, {
    OcrImageMode mode = OcrImageMode.natural,
    ImageProcessingConfig config = const ImageProcessingConfig(),
  }) async {
    final tempDir = Directory.systemTemp;
    final processedPath =
        '${tempDir.path}/ocr_${mode.name}_${DateTime.now().microsecondsSinceEpoch}.jpg';

    final params = _PreprocessParams(
      inputPath: rawImageFile.path,
      outputPath: processedPath,
      config: config,
      mode: mode,
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

    img.Image working = img.bakeOrientation(decoded);
    final config = params.config;

    if (config.cropToCard) {
      working = _cropToCard(working, config);
    }

    working = _normaliseSize(working, config);

    if (params.mode == OcrImageMode.enhanced) {
      working = img.grayscale(working);
      working = img.adjustColor(working, contrast: config.contrastBoost);
      working = img.convolution(
        working,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        div: 1,
      );
    }

    final processedBytes = img.encodeJpg(working, quality: 95);
    final outputFile = File(params.outputPath)..writeAsBytesSync(processedBytes);
    return outputFile.path;
  }

  static img.Image _cropToCard(img.Image image, ImageProcessingConfig config) {
    final imageWidth = image.width;
    final imageHeight = image.height;

    int cropWidth = (imageWidth * config.viewportScale).round();
    int cropHeight = (cropWidth / config.cardAspectRatio).round();
    if (cropHeight > imageHeight) {
      cropHeight = (imageHeight * config.viewportScale).round();
      cropWidth = (cropHeight * config.cardAspectRatio).round();
    }

    final cropX = ((imageWidth - cropWidth) / 2).clamp(0, imageWidth - 1).round();
    final cropY = ((imageHeight - cropHeight) / 2).clamp(0, imageHeight - 1).round();

    return img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );
  }

  static img.Image _normaliseSize(img.Image image, ImageProcessingConfig config) {
    final longSide = image.width > image.height ? image.width : image.height;

    if (longSide > config.maxLongSide) {
      final scale = config.maxLongSide / longSide;
      return img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.average,
      );
    }

    if (longSide < config.minLongSide) {
      final scale = config.minLongSide / longSide;
      return img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.cubic,
      );
    }

    return image;
  }
}
