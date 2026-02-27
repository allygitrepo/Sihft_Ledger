class CompanyModel {
  final String companyName;
  final String industryType;
  final String? address;
  final String? companyPhoto; // Base64 string
  final DateTime createdAt;

  const CompanyModel({
    required this.companyName,
    required this.industryType,
    this.address,
    this.companyPhoto,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'industryType': industryType,
      'address': address,
      'companyPhoto': companyPhoto,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      companyName: json['companyName'] as String,
      industryType: json['industryType'] as String,
      address: json['address'] as String?,
      companyPhoto: json['companyPhoto'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  CompanyModel copyWith({
    String? companyName,
    String? industryType,
    String? address,
    String? companyPhoto,
    DateTime? createdAt,
  }) {
    return CompanyModel(
      companyName: companyName ?? this.companyName,
      industryType: industryType ?? this.industryType,
      address: address ?? this.address,
      companyPhoto: companyPhoto ?? this.companyPhoto,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
