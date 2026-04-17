import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:porter_clone_user/core/storage/auth_local_storage.dart';
import 'package:porter_clone_user/features/dashboard/view/dashboard_page.dart';
import 'package:porter_clone_user/features/sign_in/view/sign_in_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

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
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              hasAccessToken ? const DashboardPage() : const SignInPage(),
        ),
      );
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
