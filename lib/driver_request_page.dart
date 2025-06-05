import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'Before_drive.dart';
import 'navigate_to_pickup_page.dart';

class RideRequest {
  final String docId;
  final String pickupPlaceName;
  final String destinationName;

  RideRequest({
    required this.docId,
    required this.pickupPlaceName,
    required this.destinationName,
  });

  factory RideRequest.fromMap(String id, Map<String, dynamic> map) {
    return RideRequest(
      docId: id,
      pickupPlaceName: map['pickupPlaceName'] ?? '',
      destinationName: map['destinationName'] ?? '',
    );
  }
}

class DriverRequestPage extends StatefulWidget {
  const DriverRequestPage({Key? key}) : super(key: key);

  @override
  State<DriverRequestPage> createState() => _DriverRequestPageState();
}

class _DriverRequestPageState extends State<DriverRequestPage> {
  LatLng? _driverLocation;
  String _locationError = '';
  final rideRef = FirebaseFirestore.instance.collection('ride_requests');

  @override
  void initState() {
    super.initState();
    _getDriverLocation();
  }

  Future<void> _getDriverLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _locationError = '위치 서비스가 꺼져 있습니다.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationError = '위치 권한이 거부되었습니다.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationError = '위치 권한이 영구적으로 거부되었습니다.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _driverLocation = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      setState(() => _locationError = '위치 정보 가져오기 실패: $e');
    }
  }

  Future<void> _rejectRequest(String docId) async {
    final currentDriverUid = FirebaseAuth.instance.currentUser!.uid;
    await rideRef.doc(docId).update({
      'rejectedDrivers': FieldValue.arrayUnion([currentDriverUid]),
    });
  }

  void _goToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DriverDashboardPage(
          driverName: '',
          carNumber: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth  = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    if (_locationError.isNotEmpty) {
      return Scaffold(
        body: Center(child: AutoSizeText(_locationError)),
      );
    }
    if (_driverLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: rideRef.where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AutoSizeText(
                '데이터 불러오기 실패: ${snapshot.error}',
                style: TextStyle(
                  fontSize: screenWidth * 20 / 400,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];

          // 필터: 5km 이내, 10분 이내, 본인이 거절한 요청 제외
          final now = Timestamp.now();
          final cutoff = Timestamp.fromMillisecondsSinceEpoch(
            now.millisecondsSinceEpoch - 10 * 60 * 1000,
          );
          final distCalc = ll.Distance();
          final currentDriverUid = FirebaseAuth.instance.currentUser!.uid;

          final filteredEntries = docs
              .map((d) => MapEntry(d.id, d.data() as Map<String, dynamic>))
              .where((entry) {
            final dataMap = entry.value;
            final pickupLat = dataMap['pickupLat'];
            final pickupLng = dataMap['pickupLng'];
            final createdAt = dataMap['createdAt'];
            final List<dynamic>? rejectedList =
            dataMap['rejectedDrivers'] as List<dynamic>?;

            if (pickupLat == null ||
                pickupLng == null ||
                createdAt == null ||
                createdAt is! Timestamp ||
                createdAt.compareTo(cutoff) < 0) {
              return false;
            }
            if (rejectedList != null && rejectedList.contains(currentDriverUid)) {
              return false;
            }
            final double latD = (pickupLat as num).toDouble();
            final double lngD = (pickupLng as num).toDouble();
            final double distanceKm = distCalc.as(
              ll.LengthUnit.Kilometer,
              ll.LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
              ll.LatLng(latD, lngD),
            );
            return distanceKm <= 5.0;
          }).toList();

          Widget cardContent;
          List<Widget> actionButtons = [];

          if (filteredEntries.isEmpty) {
            // 콜 대기중
            cardContent = Center(
              child: AutoSizeText(
                '콜 대기중...',
                style: TextStyle(
                  fontSize: screenWidth * 40 / 400,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            // 첫 번째 요청 가져오기
            filteredEntries.sort((a, b) {
              final tsA = a.value['createdAt'] as Timestamp;
              final tsB = b.value['createdAt'] as Timestamp;
              return tsA.compareTo(tsB);
            });
            final firstEntry = filteredEntries.first;
            final map = firstEntry.value;
            final ride = RideRequest.fromMap(firstEntry.key, map);

            final double pickupLat =
            (map['pickupLat'] as num).toDouble();
            final double pickupLng =
            (map['pickupLng'] as num).toDouble();
            final double destLat =
            ((map['destinationLat'] as num?) ?? 0).toDouble();
            final double destLng =
            ((map['destinationLng'] as num?) ?? 0).toDouble();

            cardContent = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 출발지 영역
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AutoSizeText(
                      '출발지: ',
                      style: TextStyle(
                        fontSize: screenWidth * 25 / 400,
                        fontWeight: FontWeight.bold
                      ),
                      maxLines: 1,
                      minFontSize: 12,
                    ),
                    SizedBox(width: screenWidth * 5 / 400),
                    Expanded(
                      child: AutoSizeText(
                        ride.pickupPlaceName,
                        style: TextStyle(
                          fontSize: screenWidth * 28 / 400,
                        ),
                        maxLines: 1,
                        minFontSize: 12,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 30 / 800),
                // 도착지 영역
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AutoSizeText(
                      '도착지: ',
                      style: TextStyle(
                        fontSize: screenWidth * 25 / 400,
                        fontWeight: FontWeight.bold
                      ),
                      maxLines: 1,
                      minFontSize: 12,
                    ),
                    SizedBox(width: screenWidth * 5 / 400),
                    Expanded(
                      child: AutoSizeText(
                        ride.destinationName,
                        style: TextStyle(
                          fontSize: screenWidth * 28 / 400,
                        ),
                        maxLines: 1,
                        minFontSize: 12,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ],
            );

            actionButtons = [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await rideRef.doc(ride.docId).update({'status': 'accepted'});
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NavigateToPickupPage(
                          driverLocation: LatLng(
                            _driverLocation!.latitude,
                            _driverLocation!.longitude,
                          ),
                          pickupLocation: LatLng(pickupLat, pickupLng),
                          destinationLocation: LatLng(destLat, destLng),
                          docId: ride.docId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade200,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 21 / 800,
                      horizontal: screenWidth * 30 / 400,
                    ),
                  ),
                  child: AutoSizeText(
                    '수락',
                    style: TextStyle(fontSize: screenWidth * 20 / 400),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 8 / 400),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _rejectRequest(ride.docId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 21 / 800,
                      horizontal: screenWidth * 30 / 400,
                    ),
                  ),
                  child: AutoSizeText(
                    '거절',
                    style: TextStyle(fontSize: screenWidth * 20 / 400),
                  ),
                ),
              ),
            ];
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 24 / 400,
                vertical: screenHeight * 50 / 800,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: screenHeight * 0.6,
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Center(
                            child: cardContent,
                          ),
                        ),
                        if (actionButtons.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: screenHeight * 8 / 800),
                            child: Row(
                              children: actionButtons,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _goToDashboard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade200,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 25 / 800,
                      ),
                      textStyle: TextStyle(
                        fontSize: screenWidth * 25 / 400,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const AutoSizeText('퇴근하기'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
