import 'package:share_plus/share_plus.dart';

class TripSharingService {
  static void shareTrip({
    required String tripId,
    required String pickupLocation,
    required String dropLocation,
    required String vehicleSize,
  }) {
    final String deepLink =
        'https://lorry.workwista.com/share/trip/$tripId';

    final String shareText = '''
Check out this trip request on Lorry App:

📍 Pickup: $pickupLocation
📍 Drop: $dropLocation
🚛 Vehicle: $vehicleSize

View details: $deepLink

Download Lorry App to accept this trip!
    ''';

    Share.share(shareText, subject: 'Trip Request - Lorry App');
  }
}
