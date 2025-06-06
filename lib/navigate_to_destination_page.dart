import 'dart:async';  // Timer 사용
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_request_page.dart';

class NavigationPickupDestinationPage extends StatefulWidget {
  final String requestId;
  final LatLng pickupLocation;
  final LatLng destinationLocation;

  const NavigationPickupDestinationPage({
    super.key,
    required this.requestId,
    required this.pickupLocation,
    required this.destinationLocation,
  });

  @override
  State<NavigationPickupDestinationPage> createState() =>
      _NavigationPickupDestinationPageState();
}

class _NavigationPickupDestinationPageState
    extends State<NavigationPickupDestinationPage> {
  String? errorMessage;
  bool _arrivalConfirmed = false; // 도착 버튼 눌렀는지 상태 체크용

  Future<void> _markArrival() async {
    try {
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(widget.requestId)
          .update({
        'status': 'end',  // 상태 'end'로 변경
      });

      if (mounted) {
        setState(() {
          _arrivalConfirmed = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AutoSizeText("목적지에 도착했습니다.")),
        );

        // 5초 후에 DriverRequestPage로 이동
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DriverRequestPage()),
                  (route) => false,
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = '도착 정보 업데이트 실패: $e';
      });
    }
  }

  late final CameraPosition _initialCameraPosition = CameraPosition(
    target: widget.pickupLocation,
    zoom: 16,
  );

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final markers = {
      Marker(markerId: const MarkerId('pickup'), position: widget.pickupLocation),
      Marker(markerId: const MarkerId('destination'), position: widget.destinationLocation),
    };

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: screenHeight * 65 / 800),
          Padding(
            padding: EdgeInsets.all(screenWidth * 16.0 / 400),
            child: AutoSizeText(
              '목적지로 이동 중...',
              style: TextStyle(fontSize: screenWidth * 24 / 400, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: screenHeight * 20 / 800),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              markers: markers,
              myLocationEnabled: true,
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: EdgeInsets.all(screenWidth * 8.0 / 400),
              child: AutoSizeText(errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 40.0 / 400),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _arrivalConfirmed ? null : _markArrival, // 중복 클릭 방지
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade200),
                child: AutoSizeText(
                  _arrivalConfirmed ? '도착 처리 중...' : '목적지 도착',
                  style: TextStyle(color: Colors.black, fontSize: screenWidth * 23 / 400),
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 20 / 800),
        ],
      ),
    );
  }
}