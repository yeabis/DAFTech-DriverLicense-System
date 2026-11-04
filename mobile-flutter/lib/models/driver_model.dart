class Driver {
  final String id;
  final String fullName;
  final String licenseNumber;
  final String dob;
  final String expiryDate;
  final String? createdDate;
  final String licenseType;
  final String status; // "Valid", "Expired", "Suspended"
  final String? registeredBy;

  const Driver({
    required this.id,
    required this.fullName,
    required this.licenseNumber,
    required this.dob,
    required this.expiryDate,
    this.createdDate,
    required this.licenseType,
    required this.status,
    this.registeredBy,
  });

  bool get isValid => status.toLowerCase() == 'valid';
  bool get isExpired => status.toLowerCase() == 'expired';
  bool get isSuspended => status.toLowerCase() == 'suspended';

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      licenseNumber: json['licenseNumber'] ?? json['licenseId'] ?? '',
      dob: json['dob'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      createdDate: json['createdDate'],
      licenseType: json['licenseType'] ?? 'Standard',
      status: json['status'] ?? 'Valid',
      registeredBy: json['registeredBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'licenseNumber': licenseNumber,
      'dob': dob,
      'expiryDate': expiryDate,
      'createdDate': createdDate,
      'licenseType': licenseType,
      'status': status,
      'registeredBy': registeredBy,
    };
  }
}

