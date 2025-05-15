import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'dashboard_screen.dart';
import 'officers_screen.dart';
import 'reports_screen.dart';
import 'matched_reports_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const OfficersScreen(),
    const ReportsScreen(),
    const MatchedReportsScreen(),
  ];

  final List<String> _titles = [
    "لوحة التحكم",
    "الموظفين",
    "البلاغات",
    "تطابق البلاغات",
  ];

  void _logout() {
    setState(() => _isLoading = true);
    // مثال بسيط لتسجيل الخروج
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, "/");
    });
  }

  Widget _buildNavButton(String title, IconData icon, int index) {
    final bool selected = _selectedIndex == index;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      selected: selected,
      hoverColor: Colors.white10,
      selectedTileColor: Colors.white24,
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: "Cairo",
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Row(
          children: [
            // ======= الشريط الجانبي =======
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: Color(0xFF5D4037),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    "لوحة تحكم لقيا",
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildNavButton("لوحة التحكم", Icons.dashboard, 0),
                  _buildNavButton("الموظفين", Icons.people, 1),
                  _buildNavButton("البلاغات", Icons.report, 2),
                  _buildNavButton(" تطابق البلاغات", Icons.report, 3),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5D4037),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        "تسجيل الخروج",
                        style: TextStyle(fontFamily: "Cairo"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ======= محتوى الصفحة =======
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 60,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(color: Colors.grey[100]),
                    child: Text(
                      _titles[_selectedIndex],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _isLoading
                      ? Expanded(
                    child: Center(
                      child: Lottie.asset(
                        'assets/lottie/loader.json',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  )
                      : Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _screens[_selectedIndex],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
