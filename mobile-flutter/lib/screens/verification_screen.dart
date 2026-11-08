import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../services/tesseract_ocr_service.dart';
import '../models/verification_result_model.dart';
import '../utils/date_format.dart';
import '../utils/license_parser.dart';
import '../widgets/custom_scanner_widget.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _licenseIdController = TextEditingController();

  final TesseractOcrService _ocrService = TesseractOcrService();

  File? _capturedImage;
  bool _useLiveScanner = true;
  bool _isVerifying = false;
  bool _isScanning = false;
  String? _lastScannedRaw;
  String? _errorMessage;
  VerificationResult? _result;
  String? _scannedDob;
  String? _scannedExpiryDate;

  @override
  void dispose() {
    _ocrService.dispose();
    _fullNameController.dispose();
    _licenseIdController.dispose();
    super.dispose();
  }

  Future<void> _scanFrontPhoto(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 95);
      if (pickedFile == null) return;

      setState(() {
        _capturedImage = File(pickedFile.path);
        _useLiveScanner = false;
        _isScanning = true;
      });

      final parsed = await _ocrService.scanFrontLicense(_capturedImage!);

      setState(() {
        if (parsed.fullName != null) _fullNameController.text = parsed.fullName!;
        if (parsed.licenseId != null) _licenseIdController.text = parsed.licenseId!;
        _scannedDob = parsed.dob;
        _scannedExpiryDate = parsed.expiryDate;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              parsed.licenseId != null
                  ? 'Front card scanned successfully! Details extracted.'
                  : 'Scanned, but the ID number wasn\'t readable. Please check/enter it manually.',
            ),
            backgroundColor:
                parsed.licenseId != null ? const Color(0xFF2EAA1B) : Colors.orangeAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('[FrontScan] OCR error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan notice: $e. You can fill or edit fields manually.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF262626),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scan Front License',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppTheme.accentTeal),
                  title: const Text('Take Photo of Front Card'),
                  onTap: () {
                    Navigator.pop(context);
                    _scanFrontPhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppTheme.accentTeal),
                  title: const Text('Choose Front Photo from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _scanFrontPhoto(ImageSource.gallery);
                  },
                ),
                if (_capturedImage != null)
                  ListTile(
                    leading: const Icon(Icons.qr_code_scanner, color: Colors.amber),
                    title: const Text('Switch back to Live Viewport'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _capturedImage = null;
                        _useLiveScanner = true;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_useLiveScanner || _isVerifying) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue?.trim() ?? '';
    if (rawValue.isEmpty || rawValue == _lastScannedRaw) return;
    _lastScannedRaw = rawValue;

    final parsed = LicenseParser.parseQr(rawValue);
    final licenseId = parsed.licenseId?.trim();
    if (licenseId == null || licenseId.isEmpty) return;

    setState(() {
      _licenseIdController.text = licenseId;
      if (parsed.fullName != null) _fullNameController.text = parsed.fullName!;
    });

    _verify(
      licenseId: licenseId,
      fullName: parsed.fullName,
      dob: parsed.dob,
      expiryDate: parsed.expiryDate,
    );
  }

  Future<void> _verifyManually() async {
    final licenseId = _licenseIdController.text.trim();
    if (licenseId.isEmpty) {
      setState(() => _errorMessage = 'Please enter a License ID Number');
      return;
    }
    await _verify(
      licenseId: licenseId,
      fullName: _fullNameController.text,
      dob: _scannedDob,
      expiryDate: _scannedExpiryDate,
    );
  }

  Future<void> _verify({
    required String licenseId,
    String? fullName,
    String? dob,
    String? expiryDate,
  }) async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await ApiService.verifyLicense(
        licenseId: licenseId,
        fullName: fullName,
        dob: dob,
        expiryDate: expiryDate,
      );

      if (!mounted) return;
      setState(() => _result = result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.headline}${result.fullName != null ? ' — ${result.fullName}' : ''}'),
          backgroundColor: result.isFake
              ? const Color(0xFFB31412)
              : result.isExpired
                  ? const Color(0xFFCC8400)
                  : const Color(0xFF2EAA1B),
          duration: const Duration(seconds: 3),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Verification failed. Please try again.');
      }
    } finally {
      _lastScannedRaw = null;
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              _buildScannerViewport(),

              const SizedBox(height: 16),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _showScanOptions,
                  icon: const Icon(Icons.camera_alt_outlined, size: 22),
                  label: Text(
                    _capturedImage != null ? 'Retake / Rescan Front' : 'Scan Front License',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3B37),
                    foregroundColor: AppTheme.textColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppTheme.accentTeal.withOpacity(0.5), width: 1.5),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              _buildLabeledField(
                label: 'Full name (optional)',
                controller: _fullNameController,
                hintText: 'e.g. Abebe Kebede',
              ),

              const SizedBox(height: 20),

              _buildLabeledField(
                label: 'License ID Number',
                controller: _licenseIdController,
                hintText: 'e.g. DL-982374',
                onSubmitted: (_) => _verifyManually(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyManually,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4C46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Verify License',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              if (_result != null) ...[
                const SizedBox(height: 24),
                _buildResultCard(_result!),
              ],

              const SizedBox(height: 16),

              _buildBackButton(context),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(VerificationResult result) {
    final Color color = result.isFake
        ? const Color(0xFFB31412)
        : result.isExpired
            ? const Color(0xFFCC8400)
            : const Color(0xFF2EAA1B);
    final IconData icon = result.isFake
        ? Icons.cancel_outlined
        : result.isExpired
            ? Icons.access_time
            : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.headline,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _resultRow('License ID', result.licenseId),
          if (result.fullName != null) _resultRow('Full name', result.fullName!),
          if (result.expiryDate != null) _resultRow('Expiry date', result.expiryDate!),
          _resultRow('Checked by', result.checkedBy),
          _resultRow('Checked date', formatDateTime(result.checkedDate)),
          if (result.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              result.message,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerViewport() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF383838),
        border: Border.all(
          color: _capturedImage != null ? AppTheme.accentTeal : const Color(0xFF168078),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_capturedImage != null)
              Image.file(_capturedImage!, fit: BoxFit.cover)
            else
              CustomScannerWidget(onDetect: _onBarcodeDetected),

            if (_isScanning || _isVerifying)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.accentTeal),
                      const SizedBox(height: 12),
                      Text(
                        _isScanning
                            ? 'Preprocessing & running Front OCR...'
                            : 'Verifying...',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFF168078),
              width: 1.8,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextFormField(
            controller: controller,
            enabled: !_isVerifying,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.left,
            onFieldSubmitted: onSubmitted,
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              suffixIcon: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A3B37),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: AppTheme.accentTeal.withOpacity(0.4),
              width: 1.2,
            ),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text(
          'Back',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
