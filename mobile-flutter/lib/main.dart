import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const DAFTechApp());
}

class DAFTechApp extends StatelessWidget {
  const DAFTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAFTech License System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardScreen()
    );
  }
}