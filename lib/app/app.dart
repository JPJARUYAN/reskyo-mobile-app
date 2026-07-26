import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'app_theme.dart';
import '../screens/auth/login_screen.dart';

class ReskyoApp extends StatelessWidget {
  const ReskyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
