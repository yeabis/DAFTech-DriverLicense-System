import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/verification_log_model.dart';
import '../services/api_service.dart';
import '../utils/date_format.dart';

class VerificationLogsScreen extends StatefulWidget {
  const VerificationLogsScreen({super.key});

  @override
  State<VerificationLogsScreen> createState() => _VerificationLogsScreenState();
}

class _VerificationLogsScreenState extends State<VerificationLogsScreen> {
  late Future<List<VerificationLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = ApiService.fetchLogs();
  }

  Future<void> _reload() async {
    final future = ApiService.fetchLogs();
    setState(() => _logsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Logs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _reload,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<VerificationLog>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentTeal),
              );
            }

            if (snapshot.hasError) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Could not load the scan logs.';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white38, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _reload,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final logs = snapshot.data ?? const [];
            if (logs.isEmpty) {
              return const Center(child: Text('No scan logs available.'));
            }

            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildLogCard(logs[index]),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogCard(VerificationLog log) {
    Color statusColor;
    IconData statusIcon;

    switch (log.status.toLowerCase()) {
      case 'active':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'expired':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.access_time;
        break;
      case 'fake':
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
                      log.fullName?.isNotEmpty == true ? log.fullName! : 'Unknown driver',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${log.licenseId}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    if (log.checkedBy != null && log.checkedBy!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Checked by: ${log.checkedBy}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    log.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDateTime(log.checkedDate),
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
