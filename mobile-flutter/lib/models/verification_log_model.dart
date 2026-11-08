class VerificationLog {
  final String id;
  final String licenseId;
  final String? fullName;
  final String status;
  final String? checkedBy;
  final DateTime? checkedDate;

  const VerificationLog({
    required this.id,
    required this.licenseId,
    this.fullName,
    required this.status,
    this.checkedBy,
    this.checkedDate,
  });

  factory VerificationLog.fromJson(Map<String, dynamic> json) {
    return VerificationLog(
      id: json['logId']?.toString() ?? json['id']?.toString() ?? '',
      licenseId: json['licenseId']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      status: json['verificationStatus']?.toString() ??
          json['status']?.toString() ??
          'Unknown',
      checkedBy: json['checkedBy']?.toString(),
      checkedDate: DateTime.tryParse(json['checkedDate']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logId': id,
      'licenseId': licenseId,
      'fullName': fullName,
      'verificationStatus': status,
      'checkedBy': checkedBy,
      'checkedDate': checkedDate?.toIso8601String(),
    };
  }
}
