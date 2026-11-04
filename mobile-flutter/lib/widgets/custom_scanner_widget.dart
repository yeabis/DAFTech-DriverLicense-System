import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CustomScannerWidget extends StatefulWidget {
  final Function(BarcodeCapture) onDetect;
  final Widget? overlay;

  const CustomScannerWidget({
    super.key,
    required this.onDetect,
    this.overlay,
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: widget.onDetect,
            errorBuilder: (context, error, child) {
              return Container(
                color: const Color(0xFF1E1E1E),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off_outlined, size: 44, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text(
                          'Camera unavailable',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error.errorDetails?.message ?? 'Please check camera permissions',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.overlay != null) widget.overlay!,
        ],
      ),
    );
  }
}
