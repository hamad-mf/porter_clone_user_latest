import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:porter_clone_user/core/services/profile_api_service.dart';
import 'package:porter_clone_user/core/storage/auth_local_storage.dart';
import 'package:porter_clone_user/core/storage/profile_local_storage.dart';
import 'package:porter_clone_user/features/dashboard/view/dashboard_page.dart';
import 'package:porter_clone_user/features/sign_in/view/sign_in_page.dart';
import 'package:porter_clone_user/features/trip_details/view/trip_details_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.deepLinkTripId,
  });

  final String? deepLinkTripId;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Make status bar transparent over black bg
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _startDelay();
  }

  void _startDelay() {
    _timer = Timer(const Duration(seconds: 2), () async {
      final hasAccessToken = await AuthLocalStorage.hasAccessToken();

      // Preload profile if user is logged in
      if (hasAccessToken) {
        try {
          final accessToken = await AuthLocalStorage.getAccessToken();
          if (accessToken != null && accessToken.trim().isNotEmpty) {
            final profileApiService = ProfileApiService();
            final profile = await profileApiService.viewProfile(
              accessToken: accessToken,
            );
            await ProfileLocalStorage.saveProfile(profile);
          }
        } catch (e) {
          // Graceful degradation: continue even if profile fetch fails
        }
      }

      if (!mounted) return;

      // Handle deep link routing
      if (widget.deepLinkTripId != null) {
        if (hasAccessToken) {
          // Authenticated user with deep link: navigate to TripDetailsPage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TripDetailsPage(
                tripId: widget.deepLinkTripId!,
                isFromDeepLink: true,
              ),
            ),
          );
        } else {
          // Unauthenticated user with deep link: navigate to SignInPage with trip ID
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SignInPage(
                redirectTripId: widget.deepLinkTripId,
              ),
            ),
          );
        }
      } else {
        // No deep link: standard routing
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                hasAccessToken ? const DashboardPage() : const SignInPage(),
          ),
        );
      }
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage("assets/images/logo.png"),
              width: 200,
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
}
