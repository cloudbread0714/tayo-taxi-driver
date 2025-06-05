import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_login_page.dart';

class DriverSignUpPage extends StatefulWidget {
  const DriverSignUpPage({super.key});

  @override
  State<DriverSignUpPage> createState() => _DriverSignUpPageState();
}

class _DriverSignUpPageState extends State<DriverSignUpPage> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _carNumberController = TextEditingController();

  void _signUp() async {
    final id = _idController.text.trim();
    final pw = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final carNumber = _carNumberController.text.trim();

    if ([id, pw, name, phone, carNumber].any((s) => s.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AutoSizeText('모든 필드를 입력해주세요.')),
      );
      return;
    }

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: id, password: pw);
      final user = cred.user;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .set({
          'email': id,
          'name': name,
          'phone': phone,
          'carNumber': carNumber,
          'role': 'driver',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const AutoSizeText('회원가입 성공'),
          content: AutoSizeText('아이디: $id\n이름: $name\n전화번호: $phone\n차량번호: $carNumber'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const DriverLoginPage()),
                      (route) => false,
                );
              },
              child: const AutoSizeText('확인'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      final message = (e.code == 'email-already-in-use')
          ? '중복된 아이디입니다.'
          : e.message ?? '알 수 없는 오류';
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const AutoSizeText('회원가입 실패'),
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
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: AutoSizeText('기사 회원가입', style: TextStyle(fontSize: screenWidth * 20 / 400)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 24 / 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('아이디'),
            SizedBox(height: screenHeight * 8 / 800),
            _buildInputField(controller: _idController),

            SizedBox(height: screenHeight * 24 / 800),
            _buildLabel('비밀번호'),
            SizedBox(height: screenHeight * 8 / 800),
            _buildInputField(controller: _passwordController, obscureText: true),

            SizedBox(height: screenHeight * 24 / 800),
            _buildLabel('이름'),
            SizedBox(height: screenHeight * 8 / 800),
            _buildInputField(controller: _nameController),

            SizedBox(height: screenHeight * 24 / 800),
            _buildLabel('전화번호'),
            SizedBox(height: screenHeight * 8 / 800),
            _buildInputField(controller: _phoneController, keyboardType: TextInputType.phone),

            SizedBox(height: screenHeight * 24 / 800),
            _buildLabel('차량번호'),
            SizedBox(height: screenHeight * 8 / 800),
            _buildInputField(controller: _carNumberController),

            SizedBox(height: screenHeight * 40 / 800),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: AutoSizeText('가입하기', style: TextStyle(fontSize: screenWidth * 18 / 400)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return AutoSizeText(text,
      style: TextStyle(fontSize: screenWidth * 18 / 400, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          isDense: true,
        ),
        style: TextStyle(fontSize: screenWidth * 18 / 400),
      ),
    );
  }
}
