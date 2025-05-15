import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart'; // ضروري لدعم الترجمة

class ReportDetailsScreen extends StatefulWidget {
  final String reportId;
  const ReportDetailsScreen({super.key, required this.reportId});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  Map<String, dynamic>? reportData;
  Map<String, dynamic>? userData;

  final List<String> statusSteps = ['processing', 'matched', 'delivered', 'closed', 'rejected'];

  final Map<String, Map<String, String>> statusLabels = {
    'processing': {'ar': 'قيد المعالجة', 'en': 'Processing'},
    'matched': {'ar': 'تم العثور على تطابق', 'en': 'Matched'},
    'delivered': {'ar': 'تم التسليم', 'en': 'Delivered'},
    'closed': {'ar': 'مغلق', 'en': 'Closed'},
    'rejected': {'ar': 'مرفوض', 'en': 'Rejected'},
  };

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    final snap = await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).get();
    if (snap.exists) {
      reportData = snap.data();
      if (reportData?['userId'] != null) {
        final userSnap = await FirebaseFirestore.instance.collection('users').doc(reportData!['userId']).get();
        userData = userSnap.data();
      }
      setState(() {});
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final lang = context.locale.languageCode;
    bool confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('confirm_change'), style: TextStyle(fontFamily: lang == 'ar' ? 'Cairo' : 'OpenSans')),
        content: Text('${tr('do_you_want_to_change_to')}: ${statusLabels[newStatus]?[lang] ?? newStatus}', style: TextStyle(fontFamily: lang == 'ar' ? 'Cairo' : 'OpenSans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel'), style: TextStyle(fontFamily: lang == 'ar' ? 'Cairo' : 'OpenSans')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('confirm'), style: TextStyle(fontFamily: lang == 'ar' ? 'Cairo' : 'OpenSans')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({'status': newStatus});
      _fetchReport(); // refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;

    return Directionality(
      textDirection: lang == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F2EB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
          title: Text(
            tr('report_details'),
            style: const TextStyle(color: Color(0xFF5D4037)),
          ),
          centerTitle: true,
        ),
        body: reportData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reportData!['imageUrl'] != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      reportData!['imageUrl'],
                      width: 280,
                      height: 280,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _buildDetail(tr('title_label'), reportData!['title']),
              _buildDetail(tr('description_label'), reportData!['description']),
              _buildDetail(tr('location_label'), reportData!['location']),
              _buildDetail(tr('color_label'), reportData!['color']),
              _buildDetail(tr('category_label'), reportData!['category']),
              _buildDetail(tr('type_label'), reportData!['type'] == 'found' ? tr('found_report') : tr('missing_report')),
              _buildDetail(tr('contact_number'), reportData!['contactNumber']),
              _buildDetail(tr('created_at'), _formatDate(reportData!['created_at'])),
              const SizedBox(height: 16),
              if (userData != null) ...[
                Text(tr('user_info'), style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold)),
                _buildDetail(tr('name'), userData!['name']),
                _buildDetail(tr('email'), userData!['email']),
              ],
              const SizedBox(height: 24),
              Text(tr('report_status'), style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
              const SizedBox(height: 10),
              ...statusSteps.map((step) {
                bool isActive = statusSteps.indexOf(step) <= statusSteps.indexOf(reportData!['status']);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          statusLabels[step]?[lang] ?? step,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? Colors.green.shade700 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (step != reportData!['status'])
                      TextButton(
                        onPressed: () => _updateStatus(step),
                        child: Text(tr('change'), style: const TextStyle(fontFamily: 'Cairo')),
                      ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
        ),
        child: Row(
          children: [
            Text("$label: ", style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
            const SizedBox(width: 8),
            Expanded(child: Text(value?.toString() ?? '—', style: const TextStyle(fontFamily: 'Cairo'))),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('dd MMM yyyy – hh:mm a').format(date);
    }
    return '—';
  }
}
