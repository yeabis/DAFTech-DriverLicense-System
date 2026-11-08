class VerificationResult {
  final String licenseId;
  final String? fullName;
  final String status;
  final String? expiryStatus;
  final String? expiryDate;
  final String message;
  final String checkedBy;
  final DateTime? checkedDate;

  const VerificationResult({
    required this.licenseId,
    this.fullName,
    required this.status,
    this.expiryStatus,
    this.expiryDate,
    required this.message,
    required this.checkedBy,
    this.checkedDate,
  });

  bool get isFake => status.toLowerCase() == 'fake';
  bool get isExpired => !isFake && expiryStatus?.toLowerCase() == 'expired';
  bool get isActive => !isFake && !isExpired;

  String get headline {
    if (isFake) return 'FAKE LICENSE';
    if (isExpired) return 'REAL LICENSE - EXPIRED';
    return 'REAL LICENSE - ACTIVE';
  }

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      licenseId: json['licenseId']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      status: json['status']?.toString() ?? 'Fake',
      expiryStatus: json['expiryStatus']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
      message: json['message']?.toString() ?? '',
      checkedBy: json['checkedBy']?.toString() ?? '',
      checkedDate: DateTime.tryParse(json['checkedDate']?.toString() ?? ''),
    );
  }
}

