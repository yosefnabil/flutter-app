import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF5D4037);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, int>>(
          future: _fetchDashboardStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Lottie.asset('assets/lottie/loader.json'),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'حدث خطأ: ${snapshot.error}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text(
                  'لا توجد بيانات متاحة.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            final stats = snapshot.data!;
            return GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5, // 👈 يقلل الارتفاع
              children: [
                _buildStatCard(Icons.person, 'عدد المستخدمين', stats['users']!, Colors.indigo),
                _buildStatCard(Icons.report, 'عدد البلاغات', stats['reports']!, primaryColor),
                _buildStatCard(Icons.link, 'عدد المطابقات', stats['matches']!, Colors.orange),
                _buildStatCard(Icons.report_problem, 'بلاغات الفقدان', stats['missing']!, Colors.red),
                _buildStatCard(Icons.find_in_page, 'بلاغات العثور', stats['found']!, Colors.green),
                _buildStatCard(Icons.people, 'عدد الموظفين', stats['officers']!, Colors.teal),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, int>> _fetchDashboardStats() async {
    final firestore = FirebaseFirestore.instance;

    final users = await firestore.collection('users').get();
    final officers = users.docs.where((doc) =>
    doc.data().containsKey('role') && doc['role'] == 'officer').length;

    final reports = await firestore.collection('reports').get();
    final missing = reports.docs.where((doc) =>
    doc.data().containsKey('type') && doc['type'] == 'missing').length;
    final found = reports.docs.where((doc) =>
    doc.data().containsKey('type') && doc['type'] == 'found').length;

    final matches = await firestore.collection('matches').get();

    return {
      'users': users.docs.length,
      'officers': officers,
      'reports': reports.docs.length,
      'missing': missing,
      'found': found,
      'matches': matches.docs.length,
    };
  }

  Widget _buildStatCard(IconData icon, String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Cairo')),
          const Spacer(),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
