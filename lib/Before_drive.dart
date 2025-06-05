import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tayotaxi_driver/driver_login_page.dart';
import 'driver_request_page.dart';

class DriverDashboardPage extends StatelessWidget {
  final String driverName;
  final String carNumber;

  const DriverDashboardPage({
    Key? key,
    required this.driverName,
    required this.carNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 24.0 / 400, vertical: screenHeight * 30.0 / 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 로그아웃 버튼
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black, size: 28),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DriverLoginPage()),
                          (route) => false,
                    );
                  },
                ),
              ),

              SizedBox(height: screenHeight * 12 / 800),

              // 프로필 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: driverName,
                          style: TextStyle(
                            fontSize: screenWidth * 30 / 400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' 기사님',
                          style: TextStyle(
                            fontSize: screenWidth * 25 / 400,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 48 / 800),

              // 차량 번호 카드
              Container(
                height: 180,
                padding: EdgeInsets.all(screenWidth * 24 / 400),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: AutoSizeText(
                    carNumber,
                    style: TextStyle(
                      fontSize: screenWidth * 45 / 400,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // 출근하기 버튼
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DriverRequestPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade200,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  textStyle: TextStyle(
                    fontSize: screenWidth * 25 / 400,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const AutoSizeText('출근하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
