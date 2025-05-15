import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laqya_app/admin/report_details_screen.dart';
import 'dart:ui' as ui;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String searchQuery = '';
  String selectedType = 'all';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'بحث عن بلاغ...',
                        hintStyle: const TextStyle(fontFamily: 'Cairo'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('الكل', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'found', child: Text('بلاغ عثور', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'missing', child: Text('بلاغ فقدان', style: TextStyle(fontFamily: 'Cairo'))),
                    ],
                    onChanged: (val) => setState(() => selectedType = val ?? 'all'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reports')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("لا توجد بلاغات حالياً."));
                  }

                  var reports = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final matchesQuery = data['title']?.toString().contains(searchQuery) ?? false;
                    final matchesType = selectedType == 'all' || data['type'] == selectedType;
                    return matchesQuery && matchesType;
                  }).toList();

                  if (reports.isEmpty) {
                    return const Center(child: Text("لا توجد نتائج مطابقة."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final data = reports[index].data() as Map<String, dynamic>;
                      final id = reports[index].id;
                      final title = data['title'] ?? '';
                      final type = data['type'] ?? '';
                      final status = data['status'] ?? '';
                      final createdAt = (data['created_at'] as Timestamp?)?.toDate();
                      final formattedDate = createdAt != null
                          ? DateFormat('dd/MM/yyyy – hh:mm a').format(createdAt)
                          : 'غير محدد';

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ReportDetailsScreen(reportId: id)),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: type == 'found' ? Colors.green[100] : Colors.orange[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        type == 'found' ? 'بلاغ عثور' : 'بلاغ فقدان',
                                        style: TextStyle(
                                          color: type == 'found' ? Colors.green[800] : Colors.orange[800],
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(status, style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[700])),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
                                const SizedBox(height: 6),
                                Text("تاريخ الإبلاغ: $formattedDate", style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600])),
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
      ),
    );
  }
}
