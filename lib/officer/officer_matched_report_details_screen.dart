import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui' as ui;

class OfficerMatchedReportDetailsScreen extends StatefulWidget {
  final String originalReportId;
  final String matchedReportId;

  const OfficerMatchedReportDetailsScreen({
    Key? key,
    required this.originalReportId,
    required this.matchedReportId,
  }) : super(key: key);

  @override
  State<OfficerMatchedReportDetailsScreen> createState() => _OfficerMatchedReportDetailsScreenState();
}

class _OfficerMatchedReportDetailsScreenState extends State<OfficerMatchedReportDetailsScreen> {
  Map<String, dynamic>? originalReport;
  Map<String, dynamic>? matchedReport;
  bool _isLoading = true;
  String? _selectedStatus;

  final List<String> _statusOptions = [
    'matched',
    'delivered_to_client',
    'rejected',
  ];

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      final originalSnapshot = await FirebaseFirestore.instance.collection('reports').doc(widget.originalReportId).get();
      final matchedSnapshot = await FirebaseFirestore.instance.collection('reports').doc(widget.matchedReportId).get();
      setState(() {
        originalReport = originalSnapshot.data();
        matchedReport = matchedSnapshot.data();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching reports: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('confirm_update'.tr(), style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            child: Text('cancel'.tr(), style: const TextStyle(fontFamily: 'Cairo')),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037)),
            child: Text('update_status'.tr(), style: const TextStyle(fontFamily: 'Cairo')),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await Future.wait([
        FirebaseFirestore.instance.collection('reports').doc(widget.originalReportId).update({'status': _selectedStatus}),
        FirebaseFirestore.instance.collection('reports').doc(widget.matchedReportId).update({'status': _selectedStatus}),
      ]);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('success_update'.tr())));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('error_update'.tr())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'processing': return 'status_processing'.tr();
      case 'matched': return 'status_matched'.tr();
      case 'delivered': return 'status_delivered'.tr();
      case 'delivered_to_client': return 'status_delivered_to_client'.tr();
      case 'received': return 'status_received'.tr();
      case 'closed': return 'status_closed'.tr();
      case 'rejected': return 'status_rejected'.tr();
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF5D4037),
          title: Text('matched_report_details_title'.tr(), style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? Center(
          child: Lottie.asset('assets/lottie/loader.json', width: 120, height: 120),
        )
            : (originalReport == null || matchedReport == null)
            ? Center(child: Text('no_data'.tr()))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportCard('original_report'.tr(), originalReport!),
              const SizedBox(height: 24),
              _buildReportCard('matched_report'.tr(), matchedReport!),
              const SizedBox(height: 32),
              _buildStatusDropdown(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D4037),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('update_status'.tr(), style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, Map<String, dynamic> report) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
            const Divider(height: 20),
            if (report['imageUrl'] != null) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    report['imageUrl'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildInfoRow('field_title'.tr(), report['title']),
            _buildInfoRow('field_description'.tr(), report['description']),
            _buildInfoRow('field_location'.tr(), report['location']),
            _buildInfoRow('field_color'.tr(), report['color']),
            _buildInfoRow('field_category'.tr(), report['category']),
            _buildInfoRow('field_type'.tr(), report['type'] == 'missing' ? 'missing_report'.tr() : 'found_report'.tr()),
            _buildInfoRow('field_contact'.tr(), report['contactNumber']),
            _buildInfoRow('field_status'.tr(), _translateStatus(report['status'])),
            _buildInfoRow('field_date'.tr(), _formatTime(report['time'])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value?.toString() ?? '—', style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          hint: Text('select_status'.tr(), style: const TextStyle(fontFamily: 'Cairo')),
          isExpanded: true,
          items: _statusOptions.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(_translateStatus(status), style: const TextStyle(fontFamily: 'Cairo')),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedStatus = value;
            });
          },
        ),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    try {
      return DateFormat('dd MMM yyyy – hh:mm a').format(DateTime.parse(timestamp));
    } catch (_) {
      return timestamp?.toString() ?? '—';
    }
  }
}
