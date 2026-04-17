import 'trip_acceptance.dart';

class AcceptedDriver {
  const AcceptedDriver({
    required this.driverId,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.isVerified,
    required this.acceptances,
  });

  final String driverId;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final bool isVerified;
  final List<TripAcceptance> acceptances;

  factory AcceptedDriver.fromJson(Map<String, dynamic> json) {
    final acceptancesList = json['acceptances'] as List<dynamic>?;
    
    return AcceptedDriver(
      driverId: json['driver_id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      isVerified: json['is_verified'] as bool,
      acceptances: acceptancesList != null
          ? acceptancesList
              .map((acceptance) => TripAcceptance.fromJson(acceptance as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
