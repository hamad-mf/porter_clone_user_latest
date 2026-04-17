class Trip {
  const Trip({
    required this.id,
    required this.pickupLocation,
    required this.dropLocation,
    required this.loadSize,
    required this.loadType,
    required this.vehicleSize,
    required this.bodyType,
    required this.tripStatus,
    required this.amount,
    required this.pickupTime,
    required this.name,
    required this.contactNumber,
    required this.acceptedDrivers,
  });

  final String id;
  final String pickupLocation;
  final String dropLocation;
  final String loadSize;
  final String loadType;
  final String vehicleSize;
  final String bodyType;
  final String tripStatus;
  final String amount;
  final DateTime pickupTime;
  final String name;
  final String contactNumber;
  final List<dynamic> acceptedDrivers;

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      pickupLocation: json['pickup_location'] as String,
      dropLocation: json['drop_location'] as String,
      loadSize: json['load_size'] as String,
      loadType: json['load_type'] as String,
      vehicleSize: json['vehicle_size'] as String,
      bodyType: json['body_type'] as String,
      tripStatus: json['trip_status'] as String,
      amount: json['amount'] as String,
      pickupTime: DateTime.parse(json['pickup_time'] as String),
      name: json['name'] as String,
      contactNumber: json['contact_number'] as String,
      acceptedDrivers: json['accepted_drivers'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickup_location': pickupLocation,
      'drop_location': dropLocation,
      'load_size': loadSize,
      'load_type': loadType,
      'vehicle_size': vehicleSize,
      'body_type': bodyType,
      'trip_status': tripStatus,
      'amount': amount,
      'pickup_time': pickupTime.toIso8601String(),
      'name': name,
      'contact_number': contactNumber,
      'accepted_drivers': acceptedDrivers,
    };
  }
}
