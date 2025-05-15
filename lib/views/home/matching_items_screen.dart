import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';

import 'matched_report_details_screen.dart';
import 'compare_reports_screen.dart';

class MatchingItemsScreen extends StatelessWidget {
  const MatchingItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String lang = context.locale.languageCode;
    final String fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';
    final Color brown = const Color(0xFF5D4037);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: brown,
        elevation: 0,
        title: Text(
          tr('matching_items'),
          style: TextStyle(
            fontFamily: fontFamily,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Lottie.asset(
                'assets/lottie/loader.json',
                width: 120,
                height: 120,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                tr('no_matches_found'),
                style: TextStyle(fontFamily: fontFamily, fontSize: 16),
              ),
            );
          }

          final matches = snapshot.data!.docs.toList();
          matches.sort((a, b) {
            final aDate = a['createdAt'] is Timestamp
                ? (a['createdAt'] as Timestamp).toDate()
                : DateTime(2000);
            final bDate = b['createdAt'] is Timestamp
                ? (b['createdAt'] as Timestamp).toDate()
                : DateTime(2000);
            return bDate.compareTo(aDate);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final doc = matches[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? '—';
              final matchedWithId = data['matchedWith'];
              final timestamp = data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : null;

              final formattedDate = timestamp != null
                  ? DateFormat('dd MMM yyyy - hh:mm a').format(timestamp)
                  : tr('no_date');

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: brown,
                          radius: 24,
                          child: const Icon(Icons.link, color: Colors.white),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: brown,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            tr('match_found_details'),
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        trailing: Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: fontFamily,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        onTap: () {
                          if (matchedWithId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MatchedReportDetailsScreen(reportId: matchedWithId),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: brown, width: 1.5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          icon: Icon(Icons.compare, color: brown),
                          label: Text(
                            tr('compare_reports'),
                            style: TextStyle(fontFamily: fontFamily, fontSize: 14, color: brown),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CompareReportsScreen(
                                  originalReportId: data['originalReportId'],
                                  matchedReportId: data['matchedWith'],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
