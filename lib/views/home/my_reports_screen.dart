import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:laqya_app/views/home/report_dialogs.dart';
import 'package:laqya_app/views/home/report_details_screen.dart';

class MyReportsScreen extends StatelessWidget {
   MyReportsScreen({super.key});

  final Map<String, Map<String, String>> statusTranslations = {
    'processing': {'ar': 'قيد المعالجة', 'en': 'Processing'},
    'matched': {'ar': 'تم العثور على تطابق', 'en': 'Matched'},
    'delivered': {'ar': 'تم التسليم', 'en': 'Delivered'},
    'delivered_to_client': {'ar': 'تم التسليم إلى العميل', 'en': 'Delivered to Client'},
    'received': {'ar': 'تم الاستلام', 'en': 'Received'},
    'closed': {'ar': 'مغلق', 'en': 'Closed'},
    'rejected': {'ar': 'مرفوض', 'en': 'Rejected'},
    'pending_review': {'ar': 'قيد المراجعة', 'en': 'Pending Review'},
    'in_progress': {'ar': 'جارٍ التنفيذ', 'en': 'In Progress'},
  };

  String getTranslatedStatus(String rawStatus, BuildContext context) {
    final lang = context.locale.languageCode;

    final normalizedStatus = statusTranslations.entries.firstWhere(
          (entry) =>
      entry.value['ar'] == rawStatus ||
          entry.key == rawStatus,
      orElse: () => MapEntry('unknown', {'ar': 'غير معروف', 'en': 'Unknown'}),
    ).key;

    return statusTranslations[normalizedStatus]?[lang] ?? (lang == 'ar' ? 'غير معروف' : 'Unknown');
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'processing':
      case 'pending_review':
      case 'in_progress':
        return Colors.orange;
      case 'matched':
      case 'delivered':
      case 'delivered_to_client':
      case 'received':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B2E2B),
        title: Text('my_reports'.tr(), style: TextStyle(fontFamily: fontFamily, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.brown.shade50,
      body: userId == null
          ? Center(child: Text('please_login'.tr(), style: TextStyle(fontFamily: fontFamily)))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: userId)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('no_reports'.tr(), style: TextStyle(fontFamily: fontFamily)),
            );
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final data = reports[index].data() as Map<String, dynamic>;
              final type = data['type'] == 'missing' ? 'report_missing'.tr() : 'report_found'.tr();
              final statusRaw = data['status'] ?? 'unknown';
              final translatedStatus = getTranslatedStatus(statusRaw, context);
              final imageUrl = data['imageUrl'];
              final docId = reports[index].id;

              final createdAt = data['created_at']?.toDate();
              final dateText = createdAt != null
                  ? DateFormat.yMd(lang).add_jm().format(createdAt)
                  : 'not_available'.tr();

              return Slidable(
                key: ValueKey(docId),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => _editReportDialog(context, data, docId),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                      icon: Icons.edit,
                      label: tr('edit'),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    SlidableAction(
                      onPressed: (_) => _confirmDelete(context, docId),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      icon: Icons.delete,
                      label: tr('delete'),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailsScreen(report: data, fontFamily: fontFamily),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                          backgroundColor: Colors.grey.shade300,
                          child: imageUrl == null
                              ? const Icon(Icons.image_not_supported, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'] ?? '',
                                  style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('$type · $dateText',
                                  style: TextStyle(
                                      fontFamily: fontFamily,
                                      color: Colors.grey[700],
                                      fontSize: 13)),
                              if (data['description'] != null &&
                                  data['description'].toString().trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    data['description'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: fontFamily,
                                        color: Colors.grey[600],
                                        fontSize: 13),
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text('${'status'.tr()}: $translatedStatus',
                                  style: TextStyle(
                                      fontFamily: fontFamily,
                                      color: getStatusColor(statusRaw))),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.brown),
                          onPressed: () {
                            _showReportDialog(context, data, docId);
                          },
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('delete_confirm_title'.tr()),
        content: Text('delete_confirm_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('reports').doc(docId).delete();
    }
  }

  void _editReportDialog(BuildContext context, Map<String, dynamic> data, String docId) {
    final fontFamily = context.locale.languageCode == 'ar' ? 'Cairo' : 'OpenSans';
    final titleController = TextEditingController(text: data['title']);
    final descriptionController = TextEditingController(text: data['description']);
    final colorController = TextEditingController(text: data['color']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('edit_report'.tr(), style: TextStyle(fontFamily: fontFamily)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'title'.tr()),
            ),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'description'.tr()),
            ),
            TextFormField(
              controller: colorController,
              decoration: InputDecoration(labelText: 'color'.tr()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B2E2B)),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('reports').doc(docId).update({
                'title': titleController.text,
                'description': descriptionController.text,
                'color': colorController.text,
              });
              Navigator.pop(context);
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, Map<String, dynamic> data, String docId) {
    final fontFamily = context.locale.languageCode == 'ar' ? 'Cairo' : 'OpenSans';

    final dummyController = TextEditingController(text: data['title']);
    final dummyCategory = data['category'];
    final dummyLocation = data['location'];
    final dummyPhone = data['contactNumber'];
    final dummyTime = data['time'] != null ? DateTime.tryParse(data['time']) : null;
    final dummyReportType = data['type'];
    final dummyQrUrl = data['qrUrl'];
    final dummyStatus = data['status'];

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ReportDialogs.buildSuccessDialog(
            context: context,
            docId: docId,
            title: dummyController.text,
            category: dummyCategory,
            location: dummyLocation,
            phone: dummyPhone,
            reportType: dummyReportType,
            selectedTime: dummyTime,
            qrUrl: dummyQrUrl,
            fontFamily: fontFamily,
            status: dummyStatus,
          ),
        );
      },
    );
  }
}
