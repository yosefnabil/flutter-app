import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../admin/admin_home.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final _emailController = TextEditingController(text: "admin@gmail.com");
  final _passwordController = TextEditingController(text: "12345678");

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _error;

  final String _adminEmail = "admin@gmail.com";
  final String _adminPassword = "12345678";

  Future<void> _loginAdmin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      UserCredential userCredential;

      try {
        print("🔐 محاولة تسجيل الدخول...");
        userCredential = await _auth.signInWithEmailAndPassword(
          email: _adminEmail.trim(),
          password: _adminPassword.trim(),
        );
        print("✅ تم تسجيل الدخول بنجاح!");
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          print("👤 المستخدم غير موجود، سيتم إنشاؤه الآن...");
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: _adminEmail.trim(),
            password: _adminPassword.trim(),
          );

          await FirebaseFirestore.instance
              .collection("users")
              .doc(userCredential.user!.uid)
              .set({
            'email': _adminEmail,
            'name': "Admin",
            'role': "admin",
            'createdAt': FieldValue.serverTimestamp(),
          });

          print("✅ تم إنشاء المستخدم وإضافته إلى Firestore!");
        } else {
          print("❌ خطأ أثناء تسجيل الدخول: ${e.code} | ${e.message}");
          rethrow;
        }
      }

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(_auth.currentUser!.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['role'] == "admin") {
        print("✅ تم التحقق من صلاحية الأدمن.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHome()),
        );
      } else {
        await _auth.signOut();
        setState(() {
          _error = "هذا الحساب لا يملك صلاحية الأدمن.";
        });
      }
    } catch (e) {
      print("🔥 خطأ عام: $e");
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(child: Text("هذه الصفحة مخصصة للويب فقط")),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/haram.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.3)),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "لُـقــيــا",
                    style: TextStyle(
                      fontSize: 48,
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black45,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: 420,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "لوحة تحكم الأدمن",
                          style: TextStyle(
                            fontSize: 22,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "البريد الإلكتروني",
                            labelStyle: const TextStyle(fontFamily: 'Cairo'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "كلمة المرور",
                            labelStyle: const TextStyle(fontFamily: 'Cairo'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF5D4037),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF5D4037)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _loginAdmin,
                            child: const Text(
                              "تسجيل الدخول",
                              style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontFamily: 'Cairo',
                              fontSize: 14,
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
