import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../services/tesseract_ocr_service.dart';
import '../utils/license_parser.dart';
import '../widgets/custom_scanner_widget.dart';

class CameraRegistrationScreen extends StatefulWidget {
  const CameraRegistrationScreen({super.key});

  @override
  State<CameraRegistrationScreen> createState() => _CameraRegistrationScreenState();
}

class _CameraRegistrationScreenState extends State<CameraRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _registeredByController = TextEditingController(text: 'Officer 1');
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _createdDateController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _licenseTypeController = TextEditingController(text: 'auto');
  final TextEditingController _activeStatusController = TextEditingController(text: 'Active');
  final TextEditingController _isRegisteredController = TextEditingController(text: 'Pending');

  final TesseractOcrService _ocrService = TesseractOcrService();

  File? _capturedImage;
  bool _isProcessing = false;
  bool _isRegistering = false;
  bool _useLiveScanner = true;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final id = _idController.text.trim();
    final dob = _dobController.text.trim();
    final expiry = _expiryController.text.trim();
    final createdDate = _createdDateController.text.trim();

    final missing = <String>[
      if (name.isEmpty) 'Full name',
      if (id.isEmpty) 'License ID Number',
      if (dob.isEmpty) 'DOB',
      if (expiry.isEmpty) 'Expiry Date',
      if (createdDate.isEmpty) 'Created Date',
    ];
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in: ${missing.join(', ')}')),
      );
      return;
    }

    setState(() => _isRegistering = true);
    try {
      final result = await ApiService.registerDriver(
        licenseId: id,
        fullName: name,
        dob: dob,
        expiryDate: expiry,
        licenseType: _licenseTypeController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyRegistered
                ? 'This license is already registered.'
                : 'License registered successfully for $name ($id)!',
          ),
          backgroundColor:
              result.alreadyRegistered ? Colors.orangeAccent : const Color(0xFF2EAA1B),
        ),
      );
      if (!result.alreadyRegistered) _resetForm();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _nameController.dispose();
    _idController.dispose();
    _registeredByController.dispose();
    _dobController.dispose();
    _createdDateController.dispose();
    _expiryController.dispose();
    _licenseTypeController.dispose();
    _activeStatusController.dispose();
    _isRegisteredController.dispose();
    super.dispose();
  }
  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_useLiveScanner || _capturedImage != null) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final rawValue = barcodes.first.rawValue ?? '';
      if (rawValue.trim().isNotEmpty) {
        final parsed = LicenseParser.parseQr(rawValue.trim());
        setState(() {
          if (parsed.licenseId != null) _idController.text = parsed.licenseId!;
          if (parsed.fullName != null) _nameController.text = parsed.fullName!;
          if (parsed.dob != null) _dobController.text = parsed.dob!;
          if (parsed.expiryDate != null) _expiryController.text = parsed.expiryDate!;
          if (parsed.licenseType != null) _licenseTypeController.text = parsed.licenseType!;
          _isRegisteredController.text = 'Scanned via QR';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Front Barcode/QR detected and details loaded!'),
            backgroundColor: AppTheme.accentTeal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _scanFrontLicense(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 95,
      );

      if (pickedFile == null) return;

      setState(() {
        _capturedImage = File(pickedFile.path);
        _useLiveScanner = false;
        _isProcessing = true;
      });

      final parsed = await _ocrService.scanFrontLicense(_capturedImage!);

      setState(() {
        if (parsed.fullName != null) _nameController.text = parsed.fullName!;
        if (parsed.licenseId != null) _idController.text = parsed.licenseId!;
        if (parsed.dob != null) _dobController.text = parsed.dob!;
        if (parsed.expiryDate != null) _expiryController.text = parsed.expiryDate!;
        if (parsed.createdDate != null) _createdDateController.text = parsed.createdDate!;
        if (parsed.licenseType != null) _licenseTypeController.text = parsed.licenseType!;
        _isRegisteredController.text = 'Extracted via Front OCR';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Front card scanned successfully! Details extracted.'),
            backgroundColor: Color(0xFF2EAA1B),
            duration: Duration(seconds: 3),
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
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
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
                    _scanFrontLicense(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppTheme.accentTeal),
                  title: const Text('Choose Front Photo from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _scanFrontLicense(ImageSource.gallery);
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

  void _resetForm() {
    setState(() {
      _capturedImage = null;
      _useLiveScanner = true;
      _nameController.clear();
      _idController.clear();
      _dobController.clear();
      _createdDateController.clear();
      _expiryController.clear();
      _licenseTypeController.text = 'auto';
      _activeStatusController.text = 'Active';
      _isRegisteredController.text = 'Pending';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('License Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear Form',
            onPressed: _resetForm,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
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

                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppTheme.accentTeal),
                                SizedBox(height: 12),
                                Text(
                                  'Preprocessing & running Front OCR...',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _showScanOptions,
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
              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'Manual/Edit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 16),

              _buildField('Full name', controller: _nameController, suffixIcon: Icons.edit),
              const SizedBox(height: 16),
              _buildField('License ID Number', controller: _idController, suffixIcon: Icons.edit),
              const SizedBox(height: 16),
              _buildField('Registered by', controller: _registeredByController),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildField('DOB', controller: _dobController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Created Date', controller: _createdDateController)),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildField('Expiry Date', controller: _expiryController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('License Type (Gerad)', controller: _licenseTypeController)),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildField('Active status', controller: _activeStatusController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('is Registered', controller: _isRegisteredController)),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4C46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isRegistering ? null : _register,
                  child: _isRegistering
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, {required TextEditingController controller, IconData? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF168078), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: suffixIcon != null
                  ? Icon(suffixIcon, color: Colors.white70, size: 20)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}