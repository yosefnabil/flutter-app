import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late String welcomeText;
  late String fontFamily;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final langCode = context.locale.languageCode;

      welcomeText = langCode == 'ar'
          ? 'مرحبًا بك في تطبيق لقيا'
          : 'Welcome to Laqya';

      fontFamily = langCode == 'ar' ? 'Cairo' : 'OpenSans';

      Future.delayed(const Duration(seconds: 3), () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final uid = user.uid;
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          final role = userDoc.data()?['role'];

          if (role == 'officer') {
            Navigator.pushReplacementNamed(context, '/officer-home'); // ✅ تأكد أن هذه الصفحة موجودة
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      });


      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.locale.languageCode;
    final fontFamily = langCode == 'ar' ? 'Cairo' : 'OpenSans';

    return Scaffold(
      backgroundColor: Colors.white, // خلفية بيضاء
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🌟 شعار
                Hero(
                  tag: 'appLogo',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 🌟 نص الترحيب
                Text(
                  welcomeText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4B2E2B), // بني داكن للكروت
                    fontFamily: fontFamily,
                  ),
                ),

                const SizedBox(height: 32),

                // 🌟 لوتي أنيميشن
                SizedBox(
                  height: 80,
                  width: 80,
                  child: Lottie.asset('assets/lottie/loader.json'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
