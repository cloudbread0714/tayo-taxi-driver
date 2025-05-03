import 'package:flutter/material.dart';
import 'package:tayotaxi_driver/pages/driver_request_page.dart'; // 경로 확인 필요

class DriverLoginPage extends StatelessWidget {
  const DriverLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('택시 기사 로그인')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DriverRequestPage(), // ✅ 수정됨
              ),
            );
          },
          child: const Text('로그인'),
        ),
      ),
    );
  }
}