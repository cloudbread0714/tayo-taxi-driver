import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverSignUpPage extends StatefulWidget {
  const DriverSignUpPage({super.key});

  @override
  State<DriverSignUpPage> createState() => _DriverSignUpPageState();
}

class _DriverSignUpPageState extends State<DriverSignUpPage> {
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final carNumberController = TextEditingController();  // 차량번호 컨트롤러 추가

  void _signUp() async {
    final id = idController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final carNumber = carNumberController.text.trim();

    if (id.isEmpty || password.isEmpty || name.isEmpty || phone.isEmpty || carNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요.')),
      );
      return;
    }

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: id, password: password);
      final user = cred.user;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('drivers')  // 컬렉션명 'drivers'로 통일하는게 좋습니다.
            .doc(user.uid)
            .set({
          'email': id,
          'name': name,
          'phone': phone,
          'carNumber': carNumber,  // 차량번호 저장
          'role': 'driver',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('회원가입 성공'),
          content: Text('아이디: $id\n이름: $name\n전화번호: $phone\n차량번호: $carNumber'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        message = '중복된 아이디입니다.';
      } else {
        message = e.message ?? '알 수 없는 오류';
      }
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('회원가입 실패'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기사 회원가입')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRow(
                label: '아이디',
                controller: idController,
                keyboardType: TextInputType.emailAddress,
                action: TextInputAction.next,
              ),
              _buildRow(
                label: '비밀번호',
                controller: passwordController,
                obscure: true,
                keyboardType: TextInputType.visiblePassword,
                action: TextInputAction.next,
              ),
              _buildRow(
                label: '이름',
                controller: nameController,
                keyboardType: TextInputType.text,
                action: TextInputAction.next,
              ),
              _buildRow(
                label: '전화번호',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                action: TextInputAction.next,
              ),
              _buildRow(
                label: '차량번호',  // 차량번호 입력 필드 추가
                controller: carNumberController,
                keyboardType: TextInputType.text,
                action: TextInputAction.done,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('가입하기', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    required TextInputType keyboardType,
    required TextInputAction action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              textInputAction: action,
              autocorrect: true,
              enableSuggestions: true,
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}