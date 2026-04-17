import 'package:flutter/material.dart';

import 'package:porter_clone_user/core/constants/app_constants.dart';
import 'package:porter_clone_user/core/theme/app_theme.dart';
import 'package:porter_clone_user/features/splash/view/splash_page.dart';

class LorryApp extends StatelessWidget {
  const LorryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.light(),
      home: const SplashPage(),
    );
  }
}
