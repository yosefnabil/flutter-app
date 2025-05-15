import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'add_or_edit_officer_screen.dart';

class OfficersScreen extends StatefulWidget {
  const OfficersScreen({super.key});

  @override
  State<OfficersScreen> createState() => _OfficersScreenState();
}

class _OfficersScreenState extends State<OfficersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F2EB),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔍 شريط البحث وزر الإضافة
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن موظف...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontFamily: 'Cairo'),
                      onChanged: (value) {
                        setState(() => _searchQuery = value.trim());
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5D4037),
                      side: const BorderSide(color: Color(0xFF5D4037)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    icon: const Icon(Icons.person_add),
                    label: const Text('إضافة موظف جديد', style: TextStyle(fontFamily: 'Cairo')),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddOrEditOfficerScreen(),
                        ),
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 24),
              // 📋 قائمة الموظفين
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'officer')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Lottie.asset('assets/lottie/loader.json', width: 120, height: 120),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('لا يوجد موظفين حاليًا.', style: TextStyle(fontFamily: 'Cairo')),
                      );
                    }

                    final filteredDocs = snapshot.data!.docs.where((doc) {
                      final name = doc['name']?.toString().toLowerCase() ?? '';
                      final email = doc['email']?.toString().toLowerCase() ?? '';
                      return name.contains(_searchQuery.toLowerCase()) ||
                          email.contains(_searchQuery.toLowerCase());
                    }).toList();

                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          child: ListTile(
                            title: Text(data['name'] ?? '', style: const TextStyle(fontFamily: 'Cairo')),
                            subtitle: Text(data['email'] ?? '', style: const TextStyle(fontFamily: 'Cairo')),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Colors.blueGrey),
                                  tooltip: 'عرض التفاصيل',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('تفاصيل الموظف', style: TextStyle(fontFamily: 'Cairo')),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('الاسم: ${data['name'] ?? ''}', style: const TextStyle(fontFamily: 'Cairo')),
                                            Text('البريد: ${data['email'] ?? ''}', style: const TextStyle(fontFamily: 'Cairo')),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.brown),
                                  tooltip: 'تعديل',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddOrEditOfficerScreen(
                                          officerId: doc.id,
                                          officerData: data,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'حذف',
                                  onPressed: () async {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
                                        content: const Text('هل أنت متأكد من حذف هذا الموظف؟', style: TextStyle(fontFamily: 'Cairo')),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await FirebaseFirestore.instance.collection('users').doc(doc.id).delete();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
