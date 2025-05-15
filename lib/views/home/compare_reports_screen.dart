import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'MapScreen.dart'; // تأكد من مسار الخريطة الصحيح

class CompareReportsScreen extends StatefulWidget {
  final String originalReportId;
  final String matchedReportId;

  const CompareReportsScreen({
    super.key,
    required this.originalReportId,
    required this.matchedReportId,
  });

  @override
  State<CompareReportsScreen> createState() => _CompareReportsScreenState();
}

class _CompareReportsScreenState extends State<CompareReportsScreen> {
  Map<String, dynamic> original = {};
  Map<String, dynamic> matched = {};
  bool loading = true;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchBothReports();
  }

  Future<void> _fetchBothReports() async {
    final firestore = FirebaseFirestore.instance;
    final originalSnap = await firestore.collection('reports').doc(widget.originalReportId).get();
    final matchedSnap = await firestore.collection('reports').doc(widget.matchedReportId).get();

    setState(() {
      original = originalSnap.data() ?? {};
      matched = matchedSnap.data() ?? {};
      loading = false;
    });
  }

  Future<void> _confirmMatch() async {
    setState(() => isProcessing = true);

    try {
      await FirebaseFirestore.instance.collection('reports').doc(widget.originalReportId).update({'status': 'matched'});

      final matchedSnap = await FirebaseFirestore.instance.collection('reports').doc(widget.matchedReportId).get();
      final matchedData = matchedSnap.data();

      if (matchedData != null && matchedData['userId'] != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(matchedData['userId'])
            .collection('notifications')
            .add({
          'title': tr('thanks'),
          'body': tr('item_matched_owner'),
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      setState(() {
        original['status'] = 'matched';
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('match_confirmed'))),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('error_confirming'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';
    final brown = const Color(0xFF5D4037);

    // التحقق هل المفقود تم تسليمه فعلاً
    bool isDelivered = (original['status'] == 'delivered' || original['status'] == 'تم التسليم') &&
        (matched['status'] == 'received' || matched['status'] == 'تم الاستلام');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
        centerTitle: true,
        title: Text(
          tr('compare_reports'),
          style: TextStyle(color: brown, fontFamily: fontFamily),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildReportPreview(original, tr('user_report'), fontFamily),
                    _buildReportPreview(matched, tr('matched_report'), fontFamily),
                  ],
                ),
                const SizedBox(height: 20),
                _buildComparison('description', original['description'], matched['description'], fontFamily),
                _buildComparison('location', original['location'], matched['location'], fontFamily),
                _buildComparison('color', original['color'], matched['color'], fontFamily),
                _buildComparison('category', original['category'], matched['category'], fontFamily),
                _buildComparison('type', original['type'], matched['type'], fontFamily),
                _buildComparison('status', original['status'], matched['status'], fontFamily),
                _buildComparison('contactNumber', original['contactNumber'], matched['contactNumber'], fontFamily),
                const SizedBox(height: 30),

                // هنا التحقق والرسائل
                if (isDelivered) ...[
                  Center(
                    child: Column(
                      children: [
                        Lottie.asset('assets/lottie/celebration.json', width: 200),
                        const SizedBox(height: 12),
                        Text(
                          tr('congratulations_delivered'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (original['status'] == 'matched') ...[
                  Text(
                    tr('match_confirmed_already'),
                    style: TextStyle(fontFamily: fontFamily, color: Colors.green, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
                    },
                    icon: const Icon(Icons.map),
                    label: Text(tr('go_to_office'), style: TextStyle(fontFamily: fontFamily)),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _confirmMatch,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(tr('confirm_match'), style: TextStyle(fontFamily: fontFamily)),
                  ),
                ],
              ],
            ),
          ),
          if (isProcessing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('assets/lottie/loader.json', width: 120),
                    const SizedBox(height: 16),
                    Text(
                      tr('processing'),
                      style: TextStyle(color: Colors.white, fontFamily: fontFamily, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportPreview(Map<String, dynamic> report, String label, String fontFamily) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: fontFamily)),
        const SizedBox(height: 8),
        if (report['imageUrl'] != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(report['imageUrl'], width: 120, height: 120, fit: BoxFit.cover),
          )
        else
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image_not_supported),
          ),
        const SizedBox(height: 8),
        Text(report['title'] ?? tr('not_available'), style: TextStyle(fontFamily: fontFamily)),
      ],
    );
  }

  Widget _buildComparison(String key, dynamic original, dynamic matched, String fontFamily) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(key),
            style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(original?.toString() ?? tr('not_available'), textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily)),
              ),
              const VerticalDivider(),
              Expanded(
                child: Text(matched?.toString() ?? tr('not_available'), textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
