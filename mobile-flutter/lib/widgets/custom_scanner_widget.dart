import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CustomScannerWidget extends StatefulWidget {
  final Function(BarcodeCapture) onDetect;

  const CustomScannerWidget({
    super.key,
    required this.onDetect,
  });

  @override
  State<CustomScannerWidget> createState() => _CustomScannerWidgetState();
}

class _CustomScannerWidgetState extends State<CustomScannerWidget> {
  late MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: MobileScanner(
        controller: _scannerController,
        onDetect: widget.onDetect, 
      ),
    );
  }
}