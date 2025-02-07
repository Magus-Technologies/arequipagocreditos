import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navega a la pantalla de login después de 3 segundos
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BounceInLeft(
              duration: const Duration(seconds: 2),
              child: const Column(
                children: [
                  Image(image: AssetImage("images/logo.png"), height: 200),
                  SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 50),
            const SpinKitWave(color: Colors.black, size: 50.0),
          ],
        ),
      ),
    );
  }
}
