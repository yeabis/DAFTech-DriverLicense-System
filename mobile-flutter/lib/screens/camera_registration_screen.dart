import 'package:flutter/material.dart';
import '../widgets/custom_scanner_widget.dart';
import '../core/app_theme.dart';

class CameraRegistrationScreen extends StatelessWidget {
  const CameraRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.lightBlue, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CustomScannerWidget(
                    onDetect: (capture) {
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Scan  |  Rescan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: AppTheme.textColor,
                  side: BorderSide(color: AppTheme.glassBorder, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'Manual/Edit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField('Full name', suffixIcon: Icons.edit),
              const SizedBox(height: 16),
              _buildTextField('License ID Number', suffixIcon: Icons.edit),
              const SizedBox(height: 16),
              _buildTextField('Registered by'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildTextField('DOB')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Created Date')),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('Expiry Date')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('License Type (Gerad)')),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildTextField('Active status')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('is Registered')),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {},
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {IconData? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20) : null,
          ),
        ),
      ],
    );
  }
}