import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

import '../../features/splash/view/splash_page.dart';
import '../../features/trip_details/view/trip_details_page.dart';

// Global navigator key for deep link navigation
final GlobalKey<NavigatorState> deepLinkNavigatorKey = GlobalKey<NavigatorState>();

// Storage for initial deep link trip ID
String? _initialDeepLinkTripId;

String? getInitialDeepLinkTripId() => _initialDeepLinkTripId;
void clearInitialDeepLinkTripId() => _initialDeepLinkTripId = null;

class DeepLinkHandler extends StatefulWidget {
  final Widget child;

  const DeepLinkHandler({super.key, required this.child});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks();
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    try {
      // Check if app was launched from a deep link
      final Uri? initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        debugPrint('Initial deep link detected: $initialLink');
        _handleDeepLink(initialLink, isInitialLink: true);
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }

    try {
      // Listen for deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        debugPrint('Received deep link stream: $uri');
        _handleDeepLink(uri, isInitialLink: false);
      }, onError: (error) {
        debugPrint('Error receiving deep link: $error');
      });
    } catch (e) {
      debugPrint('Error setting up deep link stream: $e');
    }
  }

  void _handleDeepLink(Uri uri, {required bool isInitialLink}) async {
    debugPrint('Processing deep link: $uri (initial: $isInitialLink)');

    String? tripId = _extractTripId(uri);

    if (tripId != null && tripId.isNotEmpty) {
      if (isInitialLink) {
        // For initial links (app launch), restart with splash screen
        _restartAppWithDeepLink(tripId);
      } else {
        // For stream links (app already running), navigate directly
        _navigateToTripDirectly(tripId);
      }
    } else {
      debugPrint('No valid trip ID found in URL: $uri');
    }
  }

  String? _extractTripId(Uri uri) {
    debugPrint('URI scheme: ${uri.scheme}');
    debugPrint('URI host: ${uri.host}');
    debugPrint('URI path: ${uri.path}');
    debugPrint('URI pathSegments: ${uri.pathSegments}');

    String? tripId;

    if (uri.scheme == 'lorry') {
      // For custom scheme: lorry://trip/[tripId]
      if (uri.host == 'trip' && uri.pathSegments.isNotEmpty) {
        tripId = uri.pathSegments[0];
        debugPrint('Extracted trip ID from custom scheme: $tripId');
      }
    } else if (uri.host == 'lorry.workwista.com') {
      // For HTTPS URLs: https://lorry.workwista.com/share/trip/[tripId]
      List<String> pathSegments = uri.pathSegments;

      if (pathSegments.length >= 3 &&
          pathSegments[0] == 'share' &&
          pathSegments[1] == 'trip') {
        tripId = pathSegments[2];
        debugPrint('Extracted trip ID from share URL: $tripId');
      } else if (pathSegments.length >= 2 && pathSegments[0] == 'trip') {
        tripId = pathSegments[1];
        debugPrint('Extracted trip ID from direct URL: $tripId');
      }
    }

    return tripId;
  }

  void _restartAppWithDeepLink(String tripId) {
    debugPrint('Restarting app with deep link trip ID: $tripId');

    // Store the trip ID for the splash screen to consume
    _initialDeepLinkTripId = tripId;

    if (deepLinkNavigatorKey.currentState != null) {
      // Clear the entire navigation stack and start fresh with splash screen
      deepLinkNavigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => SplashPage(
            deepLinkTripId: tripId,
          ),
        ),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
      debugPrint('Successfully restarted with SplashPage');
    } else {
      debugPrint('Navigator key not available for restart');
    }
  }

  void _navigateToTripDirectly(String tripId) {
    debugPrint('Navigating directly to trip ID: $tripId');

    if (!mounted) {
      debugPrint('Widget not mounted, cannot navigate');
      return;
    }

    try {
      if (deepLinkNavigatorKey.currentState != null) {
        deepLinkNavigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) {
              return TripDetailsPage(
                tripId: tripId,
                isFromDeepLink: true,
              );
            },
          ),
        );
        debugPrint('Successfully navigated to TripDetailsPage with ID: $tripId');
      } else {
        debugPrint('Navigator not available for direct navigation');
      }
    } catch (e) {
      debugPrint('Error in direct navigation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
