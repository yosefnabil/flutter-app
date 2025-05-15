import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // <-- ضروري لدعم الترجمة
import 'dart:ui' as ui;

class MatchedReportPairDetailsScreen extends StatefulWidget {
  final String originalReportId;
  final String matchedReportId;

  const MatchedReportPairDetailsScreen({
    super.key,
    required this.originalReportId,
    required this.matchedReportId,
  });

  @override
  State<MatchedReportPairDetailsScreen> createState() => _MatchedReportPairDetailsScreenState();
}

class _MatchedReportPairDetailsScreenState extends State<MatchedReportPairDetailsScreen> {
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;

  final List<String> _statuses = ['processing', 'matched', 'delivered', 'closed', 'rejected'];
  final Map<String, Map<String, String>> _statusLabels = {
    'processing': {'ar': 'قيد المعالجة', 'en': 'Processing'},
    'matched': {'ar': 'تم العثور على تطابق', 'en': 'Matched'},
    'delivered': {'ar': 'تم التسليم', 'en': 'Delivered'},
    'closed': {'ar': 'مغلق', 'en': 'Closed'},
    'rejected': {'ar': 'مرفوض', 'en': 'Rejected'},
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final firestore = FirebaseFirestore.instance;

    final originalSnapshot = await firestore.collection('reports').doc(widget.originalReportId).get();
    final matchedSnapshot = await firestore.collection('reports').doc(widget.matchedReportId).get();

    final originalData = originalSnapshot.data()!;
    final matchedData = matchedSnapshot.data()!;

    final originalUser = await firestore.collection('users').doc(originalData['userId']).get();
    final matchedUser = await firestore.collection('users').doc(matchedData['userId']).get();

    setState(() {
      _reportData = {
        'original': originalData,
        'matched': matchedData,
        'originalUser': originalUser.data(),
        'matchedUser': matchedUser.data(),
      };
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    final lang = context.locale.languageCode;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('confirm_update'), style: TextStyle(fontFamily: lang == 'ar' ? 'Cairo' : 'OpenSans')),
        content: Text(tr('confirm_update_message'), style: TextStyle(fontFamily: lang == 'ar' ? 'Cairo' : 'OpenSans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel'), style: TextStyle(fontFamily: lang == 'ar' ? 'Cairo' : 'OpenSans')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('confirm'), style: TextStyle(fontFamily: lang == 'ar' ? 'Cairo' : 'OpenSans')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('reports').doc(widget.originalReportId).update({'status': newStatus});
    await FirebaseFirestore.instance.collection('reports').doc(widget.matchedReportId).update({'status': newStatus});

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('status_updated'))));

    await _loadData();
  }

  String getStatusLabel(String status) {
    final lang = context.locale.languageCode;
    return _statusLabels[status]?[lang] ?? (lang == 'ar' ? 'غير معروف' : 'Unknown');
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';

    return Directionality(
      textDirection: lang == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F2EB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(tr('matched_reports_details'), style: TextStyle(color: Colors.black, fontFamily: fontFamily)),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reportData == null
            ? Center(child: Text(tr('error_loading'), style: TextStyle(fontFamily: fontFamily)))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildReportCard(tr('original_report'), _reportData!['original'], _reportData!['originalUser'], fontFamily)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildReportCard(tr('matched_report'), _reportData!['matched'], _reportData!['matchedUser'], fontFamily)),
                ],
              ),
              const SizedBox(height: 24),
              _buildVerticalTimeline(_reportData!['original']['status'], fontFamily),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => _showStatusUpdateDialog(),
                child: Text(tr('update_reports_status'), style: TextStyle(color: Colors.white, fontFamily: fontFamily)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusUpdateDialog() {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: _statuses.map((status) => ListTile(
          title: Text(getStatusLabel(status), style: TextStyle(fontFamily: fontFamily)),
          onTap: () {
            Navigator.pop(context);
            _updateStatus(status);
          },
        )).toList(),
      ),
    );
  }

  Widget _buildVerticalTimeline(String status, String fontFamily) {
    final currentIndex = _statuses.indexOf(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('timeline_title'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: fontFamily)),
        const SizedBox(height: 10),
        Column(
          children: _statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final s = entry.value;
            final isCompleted = index <= currentIndex;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                    if (index < _statuses.length - 1)
                      Container(
                        width: 2,
                        height: 30,
                        color: Colors.grey,
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(getStatusLabel(s), style: TextStyle(fontSize: 14, fontFamily: fontFamily, color: isCompleted ? Colors.green : Colors.black54)),
                  ),
                )
              ],
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildReportCard(String label, Map<String, dynamic> data, Map<String, dynamic>? user, String fontFamily) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: fontFamily)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(data['imageUrl'], height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 10),
            Text("${tr('name')}: ${user?['name'] ?? tr('unknown')}", style: TextStyle(fontFamily: fontFamily)),
            Text("${tr('email')}: ${user?['email'] ?? tr('not_available')}", style: TextStyle(fontFamily: fontFamily)),
            Text("${tr('title')}: ${data['title']}", style: TextStyle(fontFamily: fontFamily)),
            Text("${tr('description')}: ${data['description']}", style: TextStyle(fontFamily: fontFamily)),
            Text("${tr('location')}: ${data['location']}", style: TextStyle(fontFamily: fontFamily)),
            Text("${tr('status')}: ${getStatusLabel(data['status'])}", style: TextStyle(fontFamily: fontFamily)),
          ],
        ),
      ),
    );
  }
}
