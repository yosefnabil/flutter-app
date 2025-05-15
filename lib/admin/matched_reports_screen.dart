import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'matched_report_pair_details_screen.dart';

class MatchedReportsScreen extends StatefulWidget {
  const MatchedReportsScreen({super.key});

  @override
  State<MatchedReportsScreen> createState() => _MatchedReportsScreenState();
}

class _MatchedReportsScreenState extends State<MatchedReportsScreen> {
  String _searchText = '';

  Future<Map<String, dynamic>?> _fetchReportDetails(String reportId) async {
    final doc = await FirebaseFirestore.instance.collection('reports').doc(reportId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(data['userId']).get();
    data['userName'] = userDoc.data()?['name'] ?? 'غير معروف';
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('البلاغات المتطابقة', style: TextStyle(fontFamily: 'Cairo', color: Colors.black)),
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (value) => setState(() => _searchText = value.trim()),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: 'ابحث برقم البلاغ أو الاسم...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo'),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('matches')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final matches = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final data = matches[index].data() as Map<String, dynamic>;
                final originalId = data['originalReportId'];
                final matchedWithId = data['matchedWith'];

                return FutureBuilder(
                  future: Future.wait([
                    _fetchReportDetails(originalId),
                    _fetchReportDetails(matchedWithId),
                  ]),
                  builder: (context, AsyncSnapshot<List<Map<String, dynamic>?>> reportSnapshot) {
                    if (!reportSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(),
                      );
                    }

                    final originalReport = reportSnapshot.data![0];
                    final matchedReport = reportSnapshot.data![1];

                    final originalTitle = originalReport?['title'] ?? '';
                    final matchedTitle = matchedReport?['title'] ?? '';
                    final originalUser = originalReport?['userName'] ?? '';
                    final matchedUser = matchedReport?['userName'] ?? '';

                    final searchableText = '$originalId $originalTitle $originalUser $matchedWithId $matchedTitle $matchedUser';

                    if (_searchText.isNotEmpty && !searchableText.contains(_searchText)) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          'بلاغ رقم $originalId - $originalTitle',
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('مقدم البلاغ: $originalUser', style: const TextStyle(fontFamily: 'Cairo')),
                            const SizedBox(height: 4),
                            Text('مطابق مع بلاغ رقم $matchedWithId - $matchedTitle', style: const TextStyle(fontFamily: 'Cairo')),
                            Text('مقدم البلاغ: $matchedUser', style: const TextStyle(fontFamily: 'Cairo')),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MatchedReportPairDetailsScreen(
                                originalReportId: originalId,
                                matchedReportId: matchedWithId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}