import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class VerificationLogsScreen extends StatelessWidget {
  const VerificationLogsScreen({super.key});

  final List<Map<String, String>> _mockLogs = const [
    {
      'name': 'Abebe Kebede',
      'id': 'DL-982374',
      'time': '29/2/19, 10:45 AM',
      'status': 'Valid',
    },
    {
      'name': 'Sara Tadesse',
      'id': 'DL-102938',
      'time': '29/2/19, 09:12 AM',
      'status': 'Expired',
    },
    {
      'name': 'Dawit Alemu',
      'id': 'DL-564738',
      'time': '30/2/19, 04:30 PM',
      'status': 'Suspended',
    },
    {
      'name': 'Meron Hailu',
      'id': 'DL-443322',
      'time': '30/2/19, 02:15 PM',
      'status': 'Valid',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Logs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _mockLogs.isEmpty
            ? const Center(child: Text('No scan logs available.'))
            : ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: _mockLogs.length,
                itemBuilder: (context, index) {
                  final log = _mockLogs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildLogCard(context, log),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, Map<String, dynamic> log) {
    Color statusColor;
    IconData statusIcon;

    switch (log['status']) {
      case 'Valid':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Expired':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.access_time;
        break;
      case 'Suspended':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassBackground,
            border: Border.all(color: AppTheme.glassBorder, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${log['id']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    log['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log['time'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}