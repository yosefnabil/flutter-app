import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthGate extends StatelessWidget {
  final Widget loggedInScreen;
  final Widget loggedOutScreen;

  const AuthGate({
    super.key,
    required this.loggedInScreen,
    required this.loggedOutScreen,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF6F2EB),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return loggedInScreen; // المستخدم مسجل دخول ✅
        } else {
          return loggedOutScreen; // غير مسجل دخول ❌
        }
      },
    );
  }
}
