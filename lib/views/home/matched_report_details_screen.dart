import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class MatchedReportDetailsScreen extends StatelessWidget {
  final String reportId;

  const MatchedReportDetailsScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';
    final brown = const Color(0xFF5D4037);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(tr('matched_report_details'), style: TextStyle(fontFamily: fontFamily)),
        backgroundColor: brown,
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('reports').doc(reportId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(tr('report_not_found'), style: TextStyle(fontFamily: fontFamily)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الصورة الرئيسية
                  if (data['imageUrl'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(data['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 16),

                  Text(data['title'] ?? tr('no_title'),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brown, fontFamily: fontFamily)),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey.shade300),

                  const SizedBox(height: 12),
                  detailRow(Icons.description, data['description'], fontFamily),
                  detailRow(Icons.location_on, data['location'], fontFamily),
                  detailRow(Icons.palette, data['color'], fontFamily),
                  detailRow(Icons.category, data['category'], fontFamily),
                  detailRow(Icons.info_outline, translateStatus(data['status'] ?? ''), fontFamily),
                  detailRow(Icons.phone, data['contactNumber'], fontFamily),
                  const SizedBox(height: 12),

                  if (data['created_at'] != null)
                    detailRow(Icons.access_time,
                        DateFormat('dd MMM yyyy - hh:mm a').format((data['created_at'] as Timestamp).toDate()), fontFamily),

                  const SizedBox(height: 20),

                  // QR كود
                  if (data['qrUrl'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('qr_code'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: fontFamily)),
                        const SizedBox(height: 10),
                        Center(
                          child: Image.network(data['qrUrl'], height: 160),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget detailRow(IconData icon, dynamic value, String fontFamily) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value?.toString() ?? '—',
              style: TextStyle(fontSize: 16, fontFamily: fontFamily, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
