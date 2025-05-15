import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:laqya_app/views/home/notification_screen.dart';
import 'package:lottie/lottie.dart';

import 'main_home_content.dart';
import 'MapScreen.dart';
import 'profile_screen.dart';
import 'add_report_screen.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestNotificationPermission() async {
  final messaging = FirebaseMessaging.instance;

  // تحقق إذا الإذن موجود
  NotificationSettings settings = await messaging.getNotificationSettings();

  if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
    // الإذن غير محدد، نطلبه
    await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
  } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
    // الإذن مرفوض سابقاً، نطلب إذن التطبيق (Android)
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      // لو رفض دائماً ➔ افتح الإعدادات
      await openAppSettings();
    }
  }
}

Future<void> saveFcmToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
    }
  }
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  int _currentIndex = 0;
  late List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    fetchUserName();
    saveFcmToken();
    requestNotificationPermission(); // ✅ استدعاء التحقق وطلب الإذن هنا
  }

  Future<void> fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      setState(() {
        userName = data?['name'] ?? '';
        _pages = [
          MainHomeContent(userName: userName),
          const MapScreen(),
          ProfileScreen(userName: userName),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_currentIndex == 0 ? 220 : 100),
        child: Stack(
          children: [
            if (_currentIndex == 0)
              Container(
                height: 220,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/haram.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (_currentIndex == 0)
              Container(
                height: 220,
                width: double.infinity,
                color: Colors.black.withOpacity(0.3),
              ),
            Positioned(
              top: _currentIndex == 0 ? 50 : 40,
              left: 24,
              right: 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_currentIndex != 2)
                    Hero(
                      tag: 'user_avatar',
                      child: CircleAvatar(
                        radius: _currentIndex == 0 ? 30 : 22,
                        backgroundColor: const Color(0xFF4B2E2B),
                        child: Text(
                          userName.isNotEmpty ? userName.substring(0, 2).toUpperCase() : '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _currentIndex == 0 ? 22 : 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                  if (_currentIndex != 2) const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentIndex == 0 ? 'welcome'.tr() : _getPageTitle(),
                          style: TextStyle(
                            fontSize: _currentIndex == 0 ? 14 : 13,
                            color: Colors.white,
                            fontFamily: fontFamily,
                          ),
                        ),
                        if (_currentIndex == 0)
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: fontFamily,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_none,
                          color: _currentIndex == 0 ? Colors.white : const Color(0xFF4B2E2B),
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        },
                      ),
                      // إشعار عدد الإشعارات
                      Positioned(
                        right: 6,
                        top: 6,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('notifications')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const SizedBox(); // لا عرض إذا لا إشعارات
                            }
                            final count = snapshot.data!.docs.length;
                            return Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),

      body: _pages.isEmpty
          ? Center(
        child: Lottie.asset(
          'assets/lottie/loader.json',
          width: 120,
          height: 120,
        ),
      )
          : AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),


      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddReportScreen()),
        ),
        backgroundColor: const Color(0xFF4B2E2B),
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4B2E2B),
        unselectedItemColor: Colors.brown[300],
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
        ),
        iconSize: 26,
        elevation: 10,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: 'home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: 'lost_and_found_map'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'profile'.tr(),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_currentIndex) {
      case 1:
        return 'lost_and_found_map'.tr();
      case 2:
        return 'profile'.tr();
      default:
        return 'laqya'.tr();
    }
  }
}
