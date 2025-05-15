import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langCode = context.locale.languageCode;
    final fontFamily = langCode == 'ar' ? 'Cairo' : 'OpenSans';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🌍 زر اللغة
              Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<Locale>(
                  icon: const Icon(Icons.language, color: Color(0xFF4B2E2B)),
                  onSelected: (locale) => context.setLocale(locale),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: const Locale('ar'),
                      child: Text('arabic'.tr(), style: TextStyle(fontFamily: fontFamily)),
                    ),
                    PopupMenuItem(
                      value: const Locale('en'),
                      child: Text('english'.tr(), style: TextStyle(fontFamily: fontFamily)),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 📷 شعار
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 32),

              // 📝 عنوان
              Text(
                'lets_start'.tr(),
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4B2E2B),
                ),
              ),
              const SizedBox(height: 10),

              // 💬 وصف
              Text(
                'intro'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 15,
                  color: Colors.brown[400],
                ),
              ),

              const Spacer(),

              // 🔐 زر تسجيل الدخول
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B2E2B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'login'.tr(),
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ✍️ زر إنشاء حساب
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B2E2B),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF4B2E2B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 1,
                  ),
                  child: Text(
                    'signup'.tr(),
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 16,
                      color: const Color(0xFF4B2E2B),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
