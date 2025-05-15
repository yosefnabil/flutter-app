import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';

import 'officer_profile_screen.dart';
import 'officer_matching_screen.dart';

import 'officer_instructions_screen.dart';

class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({super.key});

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  int _currentIndex = 0;
  String officerName = '';
  late List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    fetchOfficerName();
  }

  Future<void> fetchOfficerName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      setState(() {
        officerName = data?['name'] ?? '';
        _pages = [
          const OfficerMainContent(),
          const OfficerProfileScreen(),
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
                children: [
                  if (_currentIndex != 1)
                    Hero(
                      tag: 'user_avatar',
                      child: CircleAvatar(
                        radius: _currentIndex == 0 ? 30 : 22,
                        backgroundColor: const Color(0xFF4B2E2B),
                        child: Text(
                          officerName.isNotEmpty ? officerName.substring(0, 2).toUpperCase() : '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _currentIndex == 0 ? 22 : 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ),
                    ),
                  if (_currentIndex != 1) const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentIndex == 0 ? tr('officer_home_title') : tr('profile'),
                          style: TextStyle(
                            fontSize: _currentIndex == 0 ? 14 : 13,
                            color: Colors.white,
                            fontFamily: fontFamily,
                          ),
                        ),
                        if (_currentIndex == 0)
                          Text(
                            officerName,
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
            label: tr('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: tr('profile'),
          ),
        ],
      ),
    );
  }
}

class OfficerMainContent extends StatelessWidget {
  const OfficerMainContent({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(
            icon: Icons.link,
            label: tr('matching_reports'),
            fontFamily: fontFamily,
            onTap: () => Navigator.pushNamed(context, '/officer/matching'),
          ),
          _buildCard(
            icon: Icons.qr_code_scanner,
            label: tr('scan_qr'),
            fontFamily: fontFamily,
            onTap: () => Navigator.pushNamed(context, '/officer/scan'),
          ),
          _buildCard(
            icon: Icons.info_outline,
            label: tr('instructions'),
            fontFamily: fontFamily,
            onTap: () => Navigator.pushNamed(context, '/officer/instructions'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required IconData icon, required String label, required String fontFamily, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF5D4037), size: 48),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D4037),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
