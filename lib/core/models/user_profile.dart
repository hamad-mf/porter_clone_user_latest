class UserProfile {
  const UserProfile({this.fullName, this.mobileNumber});

  final String? fullName;
  final String? mobileNumber;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name'] as String?,
      mobileNumber: json['mobile_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'mobile_number': mobileNumber,
    };
  }

  UserProfile copyWith({String? fullName, String? mobileNumber}) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
    );
  }
}
