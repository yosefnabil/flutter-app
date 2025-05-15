import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';

    final List<Map<String, dynamic>> steps = [
      {
        'icon': Icons.add_circle_outline,
        'title': tr('add_report'),
        'desc': tr('add_report_instruction'),
      },
      {
        'icon': Icons.image,
        'title': tr('attach_image'),
        'desc': tr('attach_image_instruction'),
      },
      {
        'icon': Icons.qr_code,
        'title': tr('receive_qr'),
        'desc': tr('receive_qr_instruction'),
      },
      {
        'icon': Icons.location_on,
        'title': tr('go_to_office'),
        'desc': tr('go_to_office_instruction'),
      },
      {
        'icon': Icons.verified,
        'title': tr('confirm_delivery'),
        'desc': tr('confirm_delivery_instruction'),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('instructions'), style: TextStyle(fontFamily: fontFamily, color: Colors.white)),
        backgroundColor: const Color(0xFF4B2E2B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.brown.shade50,
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(2, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4B2E2B).withOpacity(0.1),
                  ),
                  child: Icon(step['icon'], color: const Color(0xFF4B2E2B), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'].toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                          color: const Color(0xFF4B2E2B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step['desc'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontFamily: fontFamily,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
