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
    this.pickupTime,
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
  final DateTime? pickupTime;
  final String name;
  final String contactNumber;
  final List<dynamic> acceptedDrivers;

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: _readString(json['id']),
      pickupLocation: _readString(json['pickup_location']),
      dropLocation: _readString(json['drop_location']),
      loadSize: _readString(json['load_size']),
      loadType: _readString(json['load_type']),
      vehicleSize: _readString(json['vehicle_size']),
      bodyType: _readString(json['body_type']),
      tripStatus: _readString(json['trip_status']),
      amount: _readString(json['amount']),
      pickupTime: _readDateTime(json['pickup_time']),
      name: _readString(json['name']),
      contactNumber: _readString(json['contact_number']),
      acceptedDrivers: _readList(json['accepted_drivers']),
    );
  }

  static String _readString(dynamic value) {
    return value?.toString() ?? '';
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  static List<dynamic> _readList(dynamic value) {
    if (value is List) {
      return List<dynamic>.from(value);
    }
    return <dynamic>[];
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
      'pickup_time': pickupTime?.toIso8601String(),
      'name': name,
      'contact_number': contactNumber,
      'accepted_drivers': acceptedDrivers,
    };
  }
}
