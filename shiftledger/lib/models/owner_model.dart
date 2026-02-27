class OwnerModel {
  final String ownerName;
  final String mobileNumber;
  final String password;
  final String? email;
  final DateTime createdAt;

  const OwnerModel({
    required this.ownerName,
    required this.mobileNumber,
    required this.password,
    this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'ownerName': ownerName,
      'mobileNumber': mobileNumber,
      'password': password,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OwnerModel.fromJson(Map<String, dynamic> json) {
    return OwnerModel(
      ownerName: json['ownerName'] as String,
      mobileNumber: json['mobileNumber'] as String,
      password: json['password'] as String,
      email: json['email'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  OwnerModel copyWith({
    String? ownerName,
    String? mobileNumber,
    String? password,
    String? email,
    DateTime? createdAt,
  }) {
    return OwnerModel(
      ownerName: ownerName ?? this.ownerName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      password: password ?? this.password,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
