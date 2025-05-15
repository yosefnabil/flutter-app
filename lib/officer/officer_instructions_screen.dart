import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
class OfficerInstructionsScreen extends StatelessWidget {
  const OfficerInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';

    return Directionality(
      textDirection: lang == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F2EB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4B2E2B), // لون التطبيق
          elevation: 1,
          centerTitle: true, // العنوان بالوسط
          iconTheme: const IconThemeData(color: Colors.white), // لون أيقونة الرجوع أبيض
          title: Text(
            'instructions'.tr(),
            style: TextStyle(
              fontFamily: fontFamily,
              color: Colors.white, // لون النص أبيض
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildCard(
              icon: Icons.qr_code_scanner,
              title: 'scan_qr'.tr(),
              content: 'scan_qr_content'.tr(),
              fontFamily: fontFamily,
            ),
            _buildCard(
              icon: Icons.link,
              title: 'match_reports'.tr(),
              content: 'match_reports_content'.tr(),
              fontFamily: fontFamily,
            ),
            _buildCard(
              icon: Icons.update,
              title: 'update_status'.tr(),
              content: 'update_status_content'.tr(),
              fontFamily: fontFamily,
            ),
            _buildCard(
              icon: Icons.info_outline,
              title: 'view_details'.tr(),
              content: 'view_details_content'.tr(),
              fontFamily: fontFamily,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String content,
    required String fontFamily,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: const Color(0xFF5D4037)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
