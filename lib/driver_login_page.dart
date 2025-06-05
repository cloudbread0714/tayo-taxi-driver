import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tayotaxi_driver/Before_drive.dart';
import 'package:tayotaxi_driver/driver_sign_up.dart';

class DriverLoginPage extends StatefulWidget {
  const DriverLoginPage({super.key});

  @override
  State<DriverLoginPage> createState() => _DriverLoginPageState();
}

class _DriverLoginPageState extends State<DriverLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 빌드 완료 후 로그인 상태 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  // 이미 로그인된 사용자가 있으면 대시보드로 이동
  Future<void> _checkLoginStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();

      final data = snap.data() ?? {};
      final driverName = data['name'] as String? ?? '기사님';
      final carNumber  = data['carNumber'] as String? ?? '번호 없음';

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverDashboardPage(
            driverName: driverName,
            carNumber: carNumber,
          ),
        ),
      );
    }
  }

  // 이메일/비밀번호 로그인 처리 후 대시보드로 이동
  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = FirebaseAuth.instance.currentUser!;
      final snap = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();
      final data = snap.data() ?? {};
      final driverName = data['name'] as String? ?? '기사님';
      final carNumber  = data['carNumber'] as String? ?? '번호 없음';

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverDashboardPage(
            driverName: driverName,
            carNumber: carNumber,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showErrorDialog('로그인 실패', e.message ?? '알 수 없는 오류');
    }
  }

  void _goToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DriverSignUpPage()),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: AutoSizeText(title),
        content: AutoSizeText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AutoSizeText('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 24.0 / 400, vertical: screenHeight * 40.0 / 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 27 / 800),
              Center(
                child: AutoSizeText(
                  '기사용',
                  style: TextStyle(
                    fontSize: screenWidth * 24 / 400,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 16 / 800),
              Center(
                child: Icon(Icons.local_taxi, size: screenWidth * 100 / 400,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: screenHeight * 16 / 800),
              Center(
                child: AutoSizeText(
                  '로그인',
                  style: TextStyle(
                    fontSize: screenWidth * 36 / 400,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 40 / 800),
              TextField(
                controller: emailController,
                style: TextStyle(fontSize: screenWidth * 18 / 400),
                decoration: InputDecoration(
                  labelText: '아이디',
                  labelStyle: TextStyle(fontSize: screenWidth * 18 / 400),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 22.0, horizontal: 16.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 20 / 800),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(fontSize: screenWidth * 18 / 400),
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  labelStyle: TextStyle(fontSize: screenWidth * 18 / 400),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 22.0, horizontal: 16.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 30 / 800),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  backgroundColor: Colors.green.shade200,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: AutoSizeText(
                  '로그인',
                  style: TextStyle(fontSize: screenWidth * 20 / 400),
                ),
              ),
              SizedBox(height: screenHeight * 15 / 800),
              ElevatedButton(
                onPressed: _goToSignUp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  backgroundColor: Colors.green.shade200,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: AutoSizeText(
                  '회원가입',
                  style: TextStyle(fontSize: screenWidth * 20 / 400),
                ),
              ),
              SizedBox(height: screenHeight * 12 / 800),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: AutoSizeText(
                    '아이디/비밀번호 찾기',
                    style: TextStyle(
                      fontSize: screenWidth * 16 / 400,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 40 / 800),
            ],
          ),
        ),
      ),
    );
  }
}
