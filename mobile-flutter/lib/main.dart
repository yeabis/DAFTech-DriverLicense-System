import 'package:flutter/material.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'let go'
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}