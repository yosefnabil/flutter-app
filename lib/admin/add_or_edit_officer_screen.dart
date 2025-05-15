import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddOrEditOfficerScreen extends StatefulWidget {
  final String? officerId;
  final Map<String, dynamic>? officerData;

  const AddOrEditOfficerScreen({super.key, this.officerId, this.officerData});

  @override
  State<AddOrEditOfficerScreen> createState() => _AddOrEditOfficerScreenState();
}

class _AddOrEditOfficerScreenState extends State<AddOrEditOfficerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.officerData != null) {
      _nameController.text = widget.officerData!['name'] ?? '';
      _emailController.text = widget.officerData!['email'] ?? '';
      _passwordController.text = widget.officerData!['password'] ?? '';
    }
  }

  String _generateRandomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz123456789';
    return List.generate(10, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<void> _saveOfficer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final collection = FirebaseFirestore.instance.collection('users');

    try {
      if (widget.officerId == null) {
        // تسجيل المستخدم في Firebase Authentication
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        final uid = userCredential.user!.uid;

        // حفظ البيانات في Firestore
        await collection.doc(uid).set({
          'name': name,
          'email': email,
          'password': password,
          'role': 'officer',
          'uid': uid,
        });
      } else {
        // تحديث بيانات الموظف في Firestore فقط
        await collection.doc(widget.officerId).update({
          'name': name,
          'email': email,
          'password': password,
        });
      }

      // نسخ البيانات للحافظة
      await Clipboard.setData(ClipboardData(
        text: 'البريد: $email\nالرمز: $password',
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ الموظف ونسخ البيانات إلى الحافظة'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String error = '❌ حدث خطأ أثناء إنشاء الحساب: ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ حدث خطأ أثناء الحفظ: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
          title: Text(
            widget.officerId == null ? 'إضافة موظف' : 'تعديل موظف',
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Color(0xFF5D4037),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontFamily: 'Cairo'),
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'أدخل الاسم' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(fontFamily: 'Cairo'),
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'أدخل البريد' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontFamily: 'Cairo'),
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF5D4037),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'أدخل كلمة المرور'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _passwordController.text = _generateRandomPassword();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D4037),
                        padding: const EdgeInsets.all(14),
                      ),
                      child: const Icon(Icons.refresh, color: Colors.white),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save, color: Color(0xFF5D4037)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFF5D4037)),
                      ),
                    ),
                    label: Text(
                      widget.officerId == null ? 'حفظ الموظف' : 'تحديث البيانات',
                      style: const TextStyle(
                        color: Color(0xFF5D4037),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveOfficer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
