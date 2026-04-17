class TripAcceptance {
  const TripAcceptance({
    required this.acceptanceId,
    required this.tripId,
    required this.tripStatus,
    required this.pickupLocation,
    required this.dropLocation,
    required this.acceptedAt,
  });

  final String acceptanceId;
  final String tripId;
  final String tripStatus;
  final String pickupLocation;
  final String dropLocation;
  final DateTime acceptedAt;

  factory TripAcceptance.fromJson(Map<String, dynamic> json) {
    return TripAcceptance(
      acceptanceId: json['acceptance_id'] as String,
      tripId: json['trip_id'] as String,
      tripStatus: json['trip_status'] as String,
      pickupLocation: json['pickup_location'] as String,
      dropLocation: json['drop_location'] as String,
      acceptedAt: DateTime.parse(json['accepted_at'] as String),
    );
  }
}
