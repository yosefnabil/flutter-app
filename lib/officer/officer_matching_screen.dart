import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'officer_matched_report_details_screen.dart';

class OfficerMatchingReportsScreen extends StatefulWidget {
  const OfficerMatchingReportsScreen({super.key});

  @override
  State<OfficerMatchingReportsScreen> createState() => _OfficerMatchingReportsScreenState();
}

class _OfficerMatchingReportsScreenState extends State<OfficerMatchingReportsScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D4037),
        iconTheme: const IconThemeData(color: Colors.white), // ✅ زر العودة أبيض
        title: Text(
          tr('matched_reports'),
          style: TextStyle(fontFamily: fontFamily, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ✅ شريط البحث بتصميم أجمل
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() => searchQuery = value.trim());
              },
              decoration: InputDecoration(
                hintText: tr('search_here'),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5D4037)),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF5D4037)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              style: TextStyle(fontFamily: fontFamily),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matches')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      tr('no_matched_reports'),
                      style: TextStyle(fontFamily: fontFamily),
                    ),
                  );
                }

                final matches = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title']?.toLowerCase() ?? '';
                  return title.contains(searchQuery.toLowerCase()) ||
                      data['originalReportId']?.toString().contains(searchQuery) == true;
                }).toList();

                if (matches.isEmpty) {
                  return Center(
                    child: Text(
                      tr('no_results_found'),
                      style: TextStyle(fontFamily: fontFamily),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index].data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OfficerMatchedReportDetailsScreen(
                              originalReportId: match['originalReportId'],
                              matchedReportId: match['matchedWith'],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // ✅ صورة دائرية جميلة (ممكن لاحقاً تستخدم صورة من بلاغ مثلاً)
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFF5D4037),
                                child: Text(
                                  match['title'] != null && match['title'].toString().isNotEmpty
                                      ? match['title'].toString().substring(0, 1).toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Cairo'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${tr('report_number')}: ${match['originalReportId']}',
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${tr('reporter_name')}: ${match['title'] ?? '—'}',
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 20, color: Color(0xFF5D4037)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
