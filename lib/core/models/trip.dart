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
    final pickupDate = _stringValue(json['pickup_date']);
    final startTime = _stringValue(json['start_time']);
    final legacyPickupTime = _stringValue(json['pickup_time']);

    return Trip(
      id: _stringValue(json['id']),
      pickupLocation: _stringValue(json['pickup_location']),
      dropLocation: _stringValue(json['drop_location']),
      loadSize: _stringValue(json['load_size']),
      loadType: _stringValue(json['load_type']),
      vehicleSize: _stringValue(json['vehicle_size']),
      bodyType: _stringValue(json['body_type']),
      tripStatus: _stringValue(json['trip_status']),
      amount: _stringValue(json['amount']),
      pickupTime: _parsePickupTime(
        pickupDate: pickupDate,
        startTime: startTime,
        legacyPickupTime: legacyPickupTime,
      ),
      name: _stringValue(json['name']),
      contactNumber: _stringValue(json['contact_number']),
      acceptedDrivers: json['accepted_drivers'] is List
          ? List<dynamic>.from(json['accepted_drivers'] as List)
          : const [],
    );
  }

  static String _stringValue(dynamic value) => value?.toString() ?? '';

  static DateTime _parsePickupTime({
    required String pickupDate,
    required String startTime,
    required String legacyPickupTime,
  }) {
    final legacyDateTime = DateTime.tryParse(legacyPickupTime);
    if (legacyDateTime != null) {
      return legacyDateTime;
    }

    final parsedDate = DateTime.tryParse(pickupDate);
    final parsedClock = _parseClock(
      startTime.isNotEmpty ? startTime : pickupDate,
    );
    final now = DateTime.now();

    if (parsedDate != null) {
      return DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedClock?.hour ?? parsedDate.hour,
        parsedClock?.minute ?? parsedDate.minute,
      );
    }

    return DateTime(
      now.year,
      now.month,
      now.day,
      parsedClock?.hour ?? now.hour,
      parsedClock?.minute ?? now.minute,
    );
  }

  static ({int hour, int minute})? _parseClock(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return (hour: hour, minute: minute);
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
      'pickup_date': pickupTime.toIso8601String().split('T').first,
      'start_time':
          '${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}',
      'name': name,
      'contact_number': contactNumber,
      'accepted_drivers': acceptedDrivers,
    };
  }
}
