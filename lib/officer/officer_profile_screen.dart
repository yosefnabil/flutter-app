import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // <-- إضافة لوتي

class OfficerProfileScreen extends StatefulWidget {
  const OfficerProfileScreen({super.key});

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  String officerName = '';
  String email = '';
  String joined = '';
  bool isLoading = true; // <-- متغير للتحكم باللودينج

  @override
  void initState() {
    super.initState();
    fetchOfficerInfo();
  }

  Future<void> fetchOfficerInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();

      Timestamp? createdAt = data?['created_at'];
      String formattedDate = '';
      if (createdAt != null) {
        DateTime dt = createdAt.toDate();
        formattedDate = DateFormat('yyyy-MM-dd').format(dt);
      }

      setState(() {
        officerName = data?['name'] ?? '';
        email = data?['email'] ?? '';
        joined = formattedDate;
        isLoading = false; // <-- توقف اللودينج بعد تحميل البيانات
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';
    final displayName = officerName.isNotEmpty ? officerName : 'موظف';

    return Scaffold(
      backgroundColor: Colors.white,

      body: isLoading
          ? Center(
        child: Lottie.asset(
          'assets/lottie/loader.json',
          width: 150,
          height: 150,
        ),
      )
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Hero(
                tag: 'user_avatar',
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: const Color(0xFF4B2E2B),
                  child: Text(
                    displayName.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: fontFamily,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email.isNotEmpty ? email : 'لا يوجد بريد',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.brown[400],
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(height: 32),
              _infoCard(
                icon: Icons.calendar_today,
                label: 'joined_on'.tr(),
                value: joined.isNotEmpty ? joined : '----',
                fontFamily: fontFamily,
              ),
              const SizedBox(height: 32),
              _buildSettingItem(
                icon: Icons.language,
                title: 'language'.tr(),
                onTap: () => _showLanguageDialog(context, fontFamily),
                fontFamily: fontFamily,
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                icon: Icons.lock_outline,
                title: 'change_password'.tr(),
                onTap: () => _showChangePasswordDialog(context, fontFamily),
                fontFamily: fontFamily,
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                icon: Icons.logout,
                title: 'logout'.tr(),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                },
                fontFamily: fontFamily,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    required String fontFamily,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4B2E2B),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: fontFamily,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontFamily: fontFamily,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required String fontFamily,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: const Color(0xFF4B2E2B),
        borderRadius: BorderRadius.circular(16),
        elevation: 1.5,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: fontFamily,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, String fontFamily) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('language'.tr(), style: TextStyle(fontFamily: fontFamily)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("العربية", style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                context.setLocale(const Locale('ar'));
                FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({
                  'language': 'ar',
                }, SetOptions(merge: true));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("English", style: TextStyle(fontFamily: 'OpenSans')),
              onTap: () {
                context.setLocale(const Locale('en'));
                FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({
                  'language': 'en',
                }, SetOptions(merge: true));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, String fontFamily) {
    final _emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('change_password'.tr(), style: TextStyle(fontFamily: fontFamily)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('enter_your_email'.tr(), style: TextStyle(fontSize: 14, fontFamily: fontFamily)),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'email_or_phone'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(), style: TextStyle(fontFamily: fontFamily)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: _emailController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('email_sent'.tr())),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('error_try_again'.tr())),
                );
              }
            },
            child: Text('send'.tr(), style: TextStyle(fontFamily: fontFamily)),
          ),
        ],
      ),
    );
  }
}
