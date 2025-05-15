import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class ReportDialogs {
  static Widget buildSuccessDialog({
    required BuildContext context,
    required String docId,
    required String title,
    required String category,
    required String location,
    String? phone,
    required String reportType,
    DateTime? selectedTime,
    String? qrUrl,
    required String fontFamily,
    String? status,
  }) {
    final GlobalKey repaintBoundaryKey = GlobalKey();
    final lang = context.locale.languageCode;

    final statusTranslations = {
      'processing': {'ar': 'قيد المعالجة', 'en': 'Processing'},
      'matched': {'ar': 'تم العثور على تطابق', 'en': 'Matched'},
      'delivered': {'ar': 'تم التسليم', 'en': 'Delivered'},
      'closed': {'ar': 'مغلق', 'en': 'Closed'},
      'rejected': {'ar': 'مرفوض', 'en': 'Rejected'},
      'pending_review': {'ar': 'قيد المراجعة', 'en': 'Pending Review'},
      'in_progress': {'ar': 'جارٍ التنفيذ', 'en': 'In Progress'},
      'delivered_to_client': {'ar': 'تم التسليم إلى العميل', 'en': 'Delivered to Client'},
      'received': {'ar': 'تم الاستلام', 'en': 'Received'},
    };

    String translateStatus(String rawStatus) {
      final normalized = statusTranslations.entries.firstWhere(
            (entry) => entry.key == rawStatus || entry.value['ar'] == rawStatus,
        orElse: () => MapEntry('unknown', {'ar': 'غير معروف', 'en': 'Unknown'}),
      );
      return normalized.value[lang] ?? (lang == 'ar' ? 'غير معروف' : 'Unknown');
    }

    final translatedStatus = translateStatus(status ?? '');

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: RepaintBoundary(
          key: repaintBoundaryKey,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4B2E2B),
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.white, size: 64),
                  const SizedBox(height: 12),
                  Text(tr('report_sent_success'),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: fontFamily, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('${tr('report_id')}: $docId', style: TextStyle(color: Colors.white70, fontFamily: fontFamily)),
                  const SizedBox(height: 4),
                  Text('${tr('report_type')}: ${reportType == 'missing' ? tr('report_missing') : tr('report_found')}',
                      style: TextStyle(color: Colors.white70, fontFamily: fontFamily)),
                  const SizedBox(height: 4),
                  Text('${tr('status')}: $translatedStatus',
                      style: TextStyle(color: Colors.white70, fontFamily: fontFamily)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: docId,
                      version: QrVersions.auto,
                      size: 140,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr('qr_instruction'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: fontFamily, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  _styledDetail(tr('title'), title, fontFamily),
                  _styledDetail(tr('category'), category, fontFamily),
                  _styledDetail(tr('location'), location, fontFamily),
                  if (phone != null) _styledDetail(tr('contact_number'), phone, fontFamily),
                  if (selectedTime != null)
                    _styledDetail(tr('lost_time'), DateFormat.yMd(lang).add_jm().format(selectedTime), fontFamily),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final boundary = repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                            final image = await boundary.toImage(pixelRatio: 3.0);
                            final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                            final pngBytes = byteData!.buffer.asUint8List();
                            await FlutterImageGallerySaver.saveImage(pngBytes);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr('saved_as_image'), style: TextStyle(fontFamily: fontFamily))),
                            );
                          },
                          icon: const Icon(Icons.save_alt),
                          label: Text(tr('save_as_image'), style: TextStyle(fontFamily: fontFamily)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final text = '''
${tr('report_type')}: ${reportType == 'missing' ? tr('report_missing') : tr('report_found')}
${tr('title')}: $title
${tr('category')}: $category
${tr('location')}: $location
${phone != null ? "📞 $phone" : ""}
QR: $qrUrl
''';
                            await Share.share(text);
                          },
                          icon: const Icon(Icons.share),
                          label: Text(tr('share'), style: TextStyle(fontFamily: fontFamily)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _styledDetail(String label, String value, String fontFamily) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: fontFamily)),
          Expanded(child: Text(value, style: TextStyle(fontFamily: fontFamily))),
        ],
      ),
    );
  }
}
