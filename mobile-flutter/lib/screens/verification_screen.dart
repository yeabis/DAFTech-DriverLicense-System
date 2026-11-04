import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/app_theme.dart';
import '../models/driver_model.dart';
import '../widgets/custom_scanner_widget.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _licenseIdController = TextEditingController();

  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  bool _isCameraActive = true;
  bool _isSearching = false;
  String? _verificationStatus; 

  final Map<String, Driver> _mockDatabase = {
    'DL-982374': const Driver(
      id: '1',
      fullName: 'Abebe Kebede',
      licenseNumber: 'DL-982374',
      dob: '12/04/1988',
      expiryDate: '15/10/2028',
      licenseType: 'Public 1',
      status: 'Valid',
      registeredBy: 'Officer Tadesse',
    ),
    'DL-102938': const Driver(
      id: '2',
      fullName: 'Sara Tadesse',
      licenseNumber: 'DL-102938',
      dob: '24/09/1992',
      expiryDate: '01/01/2023',
      licenseType: 'Auto',
      status: 'Expired',
      registeredBy: 'Officer Abebe',
    ),
    'DL-564738': const Driver(
      id: '3',
      fullName: 'Dawit Alemu',
      licenseNumber: 'DL-564738',
      dob: '05/11/1985',
      expiryDate: '20/05/2022',
      licenseType: 'Commercial',
      status: 'Suspended',
      registeredBy: 'Officer Worku',
    ),
    'DL-443322': const Driver(
      id: '4',
      fullName: 'Meron Hailu',
      licenseNumber: 'DL-443322',
      dob: '18/07/1996',
      expiryDate: '11/08/2029',
      licenseType: 'Public 2',
      status: 'Valid',
      registeredBy: 'Officer Tadesse',
    ),
  };

  @override
  void initState() {
    super.initState();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _fullNameController.dispose();
    _licenseIdController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isCameraActive) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final rawValue = barcodes.first.rawValue ?? '';
      if (rawValue.trim().isNotEmpty) {
        _processLicenseCode(rawValue.trim());
      }
    }
  }

  void _processLicenseCode(String rawCode) {
    String searchId = rawCode;
    String? foundName;
    String status = 'Valid';

    final directMatch = _mockDatabase[searchId.toUpperCase()];
    if (directMatch != null) {
      searchId = directMatch.licenseNumber;
      foundName = directMatch.fullName;
      status = directMatch.status;
    } else {
      final matchedKey = _mockDatabase.keys.firstWhere(
        (k) => rawCode.toUpperCase().contains(k),
        orElse: () => '',
      );
      if (matchedKey.isNotEmpty) {
        final driver = _mockDatabase[matchedKey]!;
        searchId = driver.licenseNumber;
        foundName = driver.fullName;
        status = driver.status;
      } else {
        searchId = rawCode;
        foundName = _fullNameController.text.isNotEmpty
            ? _fullNameController.text
            : 'Driver (ID: $rawCode)';
        status = 'Valid';
      }
    }

    setState(() {
      _licenseIdController.text = searchId;
      if (foundName != null) {
        _fullNameController.text = foundName;
      }
      _verificationStatus = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verified: $searchId - Status: $status'),
        backgroundColor: status == 'Valid' ? const Color(0xFF2EAA1B) : const Color(0xFFB01212),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _verifyManually() {
    final idText = _licenseIdController.text.trim();
    if (idText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a License ID Number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final driver = _mockDatabase[idText.toUpperCase()];
    setState(() {
      if (driver != null) {
        _fullNameController.text = driver.fullName;
        _verificationStatus = driver.status;
      } else {
        _verificationStatus = 'Valid';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verification Result: ${_verificationStatus ?? "Valid"}'),
        backgroundColor: _verificationStatus == 'Valid'
            ? const Color(0xFF2EAA1B)
            : const Color(0xFFB01212),
      ),
    );
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

              const SizedBox(height: 28),

              _buildLabeledField(
                label: 'Full name',
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

              const SizedBox(height: 32),

              _buildStatusButton(
                title: 'Valid',
                backgroundColor: const Color(0xFF2EAA1B),
                isSelected: _verificationStatus?.toLowerCase() == 'valid',
                onTap: () {
                  setState(() {
                    _verificationStatus = 'Valid';
                  });
                  _verifyManually();
                },
              ),

              const SizedBox(height: 16),

              _buildStatusButton(
                title: 'Expired',
                backgroundColor: const Color(0xFFB31412),
                isSelected: _verificationStatus?.toLowerCase() == 'expired',
                onTap: () {
                  setState(() {
                    _verificationStatus = 'Expired';
                  });
                },
              ),

              const SizedBox(height: 16),

              _buildBackButton(context),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerViewport() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF4A4A4A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isCameraActive)
              Positioned.fill(
                child: CustomScannerWidget(
                  onDetect: _onBarcodeDetected,
                ),
              ),

            Center(
              child: Container(
                width: 250,
                height: 155,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  border: Border.all(color: Colors.white60, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white38, width: 1),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white54,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'License Type (Gerad)',
                                style: TextStyle(color: Colors.white70, fontSize: 8),
                              ),
                              Text(
                                'License ID number',
                                style: TextStyle(color: Colors.white70, fontSize: 8),
                              ),
                            ],
                          ),
                          Text(
                            'Full Name',
                            style: TextStyle(color: Colors.white70, fontSize: 8),
                          ),
                          Text(
                            'Date of birth',
                            style: TextStyle(color: Colors.white70, fontSize: 8),
                          ),
                          Text(
                            'Created date',
                            style: TextStyle(color: Colors.white70, fontSize: 8),
                          ),
                          Text(
                            'Expiry date',
                            style: TextStyle(color: Colors.white70, fontSize: 8),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              'Registered by user',
                              style: TextStyle(color: Colors.white54, fontSize: 7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            AnimatedBuilder(
              animation: _laserAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 280 * _laserAnimation.value,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DD3D3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1DD3D3).withOpacity(0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: Icon(
                    _isCameraActive ? Icons.camera_alt : Icons.camera_alt_outlined,
                    color: _isCameraActive ? AppTheme.accentTeal : Colors.white70,
                    size: 20,
                  ),
                  tooltip: 'Toggle Camera',
                  onPressed: () {
                    setState(() {
                      _isCameraActive = !_isCameraActive;
                    });
                  },
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

  Widget _buildStatusButton({
    required String title,
    required Color backgroundColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: isSelected ? 6 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: isSelected
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(
                title == 'Valid' ? Icons.check_circle : Icons.warning_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
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
