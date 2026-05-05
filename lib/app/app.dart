import 'package:flutter/material.dart';

import 'package:porter_clone_user/core/constants/app_constants.dart';
import 'package:porter_clone_user/core/theme/app_theme.dart';
import 'package:porter_clone_user/features/splash/view/splash_page.dart';
import 'package:porter_clone_user/core/handlers/deep_link_handler.dart';

class LorryApp extends StatefulWidget {
  const LorryApp({super.key});

  @override
  State<LorryApp> createState() => _LorryAppState();
}

class _LorryAppState extends State<LorryApp> {
  String? _initialDeepLinkTripId;

  @override
  void initState() {
    super.initState();
    // Check for initial deep link trip ID
    _initialDeepLinkTripId = getInitialDeepLinkTripId();
    // Clear it after consuming to prevent reuse
    if (_initialDeepLinkTripId != null) {
      clearInitialDeepLinkTripId();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.light(),
      navigatorKey: deepLinkNavigatorKey,
      home: SplashPage(
        deepLinkTripId: _initialDeepLinkTripId,
      ),
    );
  }
}
