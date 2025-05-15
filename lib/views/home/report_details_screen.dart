import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class ReportDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> report;
  final String fontFamily;

  const ReportDetailsScreen({super.key, required this.report, required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final createdAt = report['created_at']?.toDate();
    final formattedDate = createdAt != null
        ? DateFormat.yMd(lang).add_jm().format(createdAt)
        : 'not_available'.tr();

    final statusTranslations = {
      'processing': {'ar': 'قيد المعالجة', 'en': 'Processing'},
      'matched': {'ar': 'تم العثور على تطابق', 'en': 'Matched'},
      'delivered': {'ar': 'تم التسليم', 'en': 'Delivered'},
      'closed': {'ar': 'مغلق', 'en': 'Closed'},
      'rejected': {'ar': 'مرفوض', 'en': 'Rejected'},
      'pending_review': {'ar': 'قيد المراجعة', 'en': 'Pending Review'},
      'in_progress': {'ar': 'جارٍ التنفيذ', 'en': 'In Progress'},
      'received': {'ar': 'تم الاستلام', 'en': 'Received'},
      'delivered_to_client': {'ar': 'تم التسليم للعميل', 'en': 'Delivered to Client'},
    };

    String translateStatus(String rawStatus) {
      final normalized = statusTranslations.entries.firstWhere(
            (entry) => entry.key == rawStatus || entry.value['ar'] == rawStatus,
        orElse: () => MapEntry('unknown', {'ar': 'غير معروف', 'en': 'Unknown'}),
      );
      return normalized.value[lang] ?? (lang == 'ar' ? 'غير معروف' : 'Unknown');
    }

    final translatedStatus = translateStatus(report['status'] ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('report_details'), style: TextStyle(fontFamily: fontFamily, color: Colors.white)),
        backgroundColor: const Color(0xFF4B2E2B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report['imageUrl'] != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(report['imageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            _buildDetailCard(context, [
              _buildDetail(context, tr('title'), report['title']),
              _buildDetail(context, tr('description'), report['description']),
              _buildDetail(context, tr('category'), report['category']),
              _buildDetail(context, tr('color'), report['color']),
              _buildDetail(context, tr('location'), report['location']),
              _buildDetail(context, tr('contact_number'), report['contactNumber']),
              _buildDetail(
                  context,
                  tr('report_type'),
                  report['type'] == 'missing' ? tr('report_missing') : tr('report_found')),
              _buildDetail(
                  context,
                  tr('time'),
                  report['time'] != null ? DateFormat.yMd(lang).add_jm().format(DateTime.tryParse(report['time'])!) : 'not_available'.tr()),
              _buildDetail(context, tr('created_at'), formattedDate),
              _buildDetail(context, tr('status'), translatedStatus),
            ]),
            const SizedBox(height: 24),
            if (report['qrUrl'] != null)
              Center(
                child: Column(
                  children: [
                    Text(tr('qr_code'),
                        style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: QrImageView(
                        data: report['qrUrl'],
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            Text(tr('timeline'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: fontFamily)),
            const SizedBox(height: 16),
            _buildTimelineCard([
              _buildTimelineStep('processing', report['status'], fontFamily),
              _buildTimelineStep('pending_review', report['status'], fontFamily),
              _buildTimelineStep('matched', report['status'], fontFamily),
              _buildTimelineStep('in_progress', report['status'], fontFamily),
              _buildTimelineStep('delivered', report['status'], fontFamily),
              _buildTimelineStep('closed', report['status'], fontFamily),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.brown.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTimelineCard(List<Widget> steps) {
    return Column(children: steps);
  }

  Widget _buildDetail(BuildContext context, String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontFamily: fontFamily, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.brown.shade100),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(value ?? '-', style: TextStyle(fontFamily: fontFamily)),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(String key, String? currentStatus, String fontFamily) {
    final isReached = _statusReached(currentStatus, key);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isReached ? const Color(0xFF4B2E2B) : Colors.grey[300],
              ),
              child: Icon(Icons.check, color: Colors.white, size: 16),
            ),
            Container(
              width: 2,
              height: 40,
              color: Colors.grey[300],
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tr(key),
            style: TextStyle(
              fontFamily: fontFamily,
              color: isReached ? const Color(0xFF4B2E2B) : Colors.grey,
              fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  bool _statusReached(String? current, String step) {
    const order = [
      'processing',
      'pending_review',
      'matched',
      'in_progress',
      'delivered',
      'closed',
    ];
    final currentIndex = order.indexOf(current ?? '');
    final stepIndex = order.indexOf(step);
    return currentIndex >= stepIndex;
  }
}
