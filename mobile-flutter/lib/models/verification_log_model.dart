class VerificationLog {
  final String id;
  final String name;
  final String licenseId;
  final String time;
  final String status;

  const VerificationLog({
    required this.id,
    required this.name,
    required this.licenseId,
    required this.time,
    required this.status,
  });

  factory VerificationLog.fromJson(Map<String, dynamic> json) {
    return VerificationLog(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      licenseId: json['licenseId'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? 'Valid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'licenseId': licenseId,
      'time': time,
      'status': status,
    };
  }
}

