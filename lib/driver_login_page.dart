import 'package:flutter/material.dart';
import 'package:tayotaxi_driver/pages/driver_request_page.dart'; // 파일 위치에 맞게 경로 수정

class DriverLoginPage extends StatelessWidget {
  const DriverLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('택시 기사 로그인')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // 예시용 빈 리스트 전달
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DriverRequestPage(requests: []),
              ),
            );
          },
          child: const Text('로그인'),
        ),
      ),
    );
  }
}