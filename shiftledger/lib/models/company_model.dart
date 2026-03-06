class CompanyModel {
  final String? id; // Backend ID
  final String companyName;
  final String industryType;
  final String? address;
  final String? companyPhoto; // Base64 string
  final DateTime createdAt;

  const CompanyModel({
    this.id,
    required this.companyName,
    required this.industryType,
    this.address,
    this.companyPhoto,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'industryType': industryType,
      'address': address,
      'companyPhoto': companyPhoto,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id']?.toString(),
      companyName: json['companyName'] as String,
      industryType: json['industryType'] as String,
      address: json['address'] as String?,
      companyPhoto: json['companyPhoto'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  CompanyModel copyWith({
    String? id,
    String? companyName,
    String? industryType,
    String? address,
    String? companyPhoto,
    DateTime? createdAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      industryType: industryType ?? this.industryType,
      address: address ?? this.address,
      companyPhoto: companyPhoto ?? this.companyPhoto,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
