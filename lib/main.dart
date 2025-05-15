import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'admin/web_login_screen.dart';
import 'firebase_options.dart';
import 'officer/officer_home.dart';
import 'officer/officer_instructions_screen.dart';
import 'officer/officer_matching_screen.dart';
import 'views/splash/splash_screen.dart';
import 'views/welcome/welcome_screen.dart';
import 'views/auth/forgot_password_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/home/home_screen.dart';
import 'views/home/matching_items_screen.dart';

import 'views/home/my_reports_screen.dart';
import 'views/home/MapScreen.dart';
import 'views/home/instructions_screen.dart';
import 'views/home/add_report_screen.dart';
import 'views/home/notification_screen.dart';

import 'officer/officer_qr_scan_screen.dart';
// ✅ تم إضافتها هنا

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showLocalNotification(message);
  print("🔔 رسالة في الخلفية: ${message.messageId}");
}

void _showLocalNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'laqya_channel_id',
    'Luqya Notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails =
  NotificationDetails(android: androidDetails);


  await flutterLocalNotificationsPlugin.show(
    message.notification.hashCode,
    message.notification?.title ?? 'إشعار',
    message.notification?.body ?? '',
    platformDetails,
  );
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await EasyLocalization.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const LaqyaApp(),
    ),
  );
}

class LaqyaApp extends StatelessWidget {
  const LaqyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    return MaterialApp(
      title: 'Laqya App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'OpenSans',
        scaffoldBackgroundColor: const Color(0xFFF6F2EB),
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      initialRoute: '/',
      routes: {
        '/': (_) =>
        kIsWeb ? const WebLoginScreen() : const SplashScreen(), // ✅ تم التحقق
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/home': (_) => const HomeScreen(),

        '/matching-items': (_) => const MatchingItemsScreen(),
        '/my-reports': (_) =>  MyReportsScreen(),
        '/map': (_) => const MapScreen(),
        '/instructions': (_) => const InstructionsScreen(),
        '/add-report': (_) => const AddReportScreen(),
        '/notification': (_) => const NotificationsScreen(),
        '/officer-home': (_) => const OfficerHomeScreen(),
        '/officer/matching': (_) => const OfficerMatchingReportsScreen(),
        '/officer/instructions': (_) => const OfficerInstructionsScreen(),
        '/officer/scan': (_) => const OfficerQRScanScreen(),


      },
    );
  }
}
