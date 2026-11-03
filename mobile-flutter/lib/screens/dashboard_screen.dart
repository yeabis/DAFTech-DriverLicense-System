import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'camera_registration_screen.dart';
import 'verification_logs_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                'Welcome, Officer',
                style: Theme.of(context).textTheme.titleLarge, 
              ),
              const SizedBox(height: 20),
              Text(
                'User 1',
                style: Theme.of(context).textTheme.titleLarge, 
              ),
              const SizedBox(height: 40),
              
              Expanded(
                child: GridView.count(
                  crossAxisCount: 1,
                  childAspectRatio: 4.5, 
                  mainAxisSpacing: 16,
                  children: [
                    _buildGlassCard(
                      context,
                      title: 'Register New License',
                      subtitle: 'Scan and save ID data',
                      icon: Icons.camera_alt_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CameraRegistrationScreen(),
                          ),
                        );
                      },
                    ),
                    _buildGlassCard(
                      context,
                      title: 'Verify License',
                      subtitle: 'Check against database',
                      icon: Icons.verified_user_outlined,
                      onTap: () {},
                    ),
                    _buildGlassCard(
                      context,
                      title: 'View Scan Logs',
                      subtitle: 'History of recent checks',
                      icon: Icons.history,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VerificationLogsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('LOGOUT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassBackground, 
              border: Border.all(color: AppTheme.glassBorder, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.accentTeal, size: 40),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}