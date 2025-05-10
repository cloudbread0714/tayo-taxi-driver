import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tayotaxi_driver/driver_login_page.dart';
import 'package:tayotaxi_driver/navigate_to_pickup_page.dart';
import 'package:latlong2/latlong.dart' as ll;

class RideRequest {
  final String passengerId;
  final String pickupPlaceName;
  final String destinationName;

  RideRequest({
    required this.passengerId,
    required this.pickupPlaceName,
    required this.destinationName,
  });

  factory RideRequest.fromMap(Map<String, dynamic> map) {
    return RideRequest(
      passengerId: map['passengerId'] ?? '',
      pickupPlaceName: map['pickupPlaceName'] ?? '',
      destinationName: map['destinationName'] ?? '',
    );
  }
}

class DriverRequestPage extends StatefulWidget {
  const DriverRequestPage({super.key});

  @override
  State<DriverRequestPage> createState() => _DriverRequestPageState();
}

class _DriverRequestPageState extends State<DriverRequestPage> {
  LatLng? _driverLocation;
  String _locationError = '';

  @override
  void initState() {
    super.initState();
    _getDriverLocation();
  }

  Future<void> _getDriverLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
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

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _driverLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      setState(() => _locationError = '위치 정보 가져오기 실패: $e');
    }
  }

  bool _isWithinRadius(LatLng pickup, double radiusKm) {
    final ll.Distance distance = ll.Distance();
    return distance.as(
      ll.LengthUnit.Kilometer,
      ll.LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
      ll.LatLng(pickup.latitude, pickup.longitude),
    ) <= radiusKm;
  }

  @override
  Widget build(BuildContext context) {
    final rideRequestRef = FirebaseFirestore.instance.collection('ride_requests');

    if (_locationError.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('위치 오류')),
        body: Center(child: Text(_locationError, style: const TextStyle(fontSize: 16))),
      );
    }

    if (_driverLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 승차 요청'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DriverLoginPage()),
                    (route) => false,
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: rideRequestRef.where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('데이터 불러오기 실패: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final now = Timestamp.now();
          final tenMinutesAgo = Timestamp.fromMillisecondsSinceEpoch(
            now.millisecondsSinceEpoch - 10 * 60 * 1000,
          );

          final ll.Distance distance = ll.Distance();

          final filtered = docs.where((doc) {
            final map = doc.data() as Map<String, dynamic>;
            final pickupLat = map['pickupLat'];
            final pickupLng = map['pickupLng'];
            final createdAt = map['createdAt'];

            if (pickupLat == null || pickupLng == null || createdAt == null) return false;
            if (createdAt is! Timestamp || createdAt.compareTo(tenMinutesAgo) < 0) return false;

            final pickup = LatLng(pickupLat.toDouble(), pickupLng.toDouble());
            return _isWithinRadius(pickup, 5.0);
          }).toList();

          filtered.sort((a, b) {
            final mapA = a.data() as Map<String, dynamic>;
            final mapB = b.data() as Map<String, dynamic>;

            final pickupA = LatLng(mapA['pickupLat'], mapA['pickupLng']);
            final pickupB = LatLng(mapB['pickupLat'], mapB['pickupLng']);

            final distA = distance.as(
              ll.LengthUnit.Kilometer,
              ll.LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
              ll.LatLng(pickupA.latitude, pickupA.longitude),
            );

            final distB = distance.as(
              ll.LengthUnit.Kilometer,
              ll.LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
              ll.LatLng(pickupB.latitude, pickupB.longitude),
            );

            return distA.compareTo(distB);
          });

          if (filtered.isEmpty) {
            return const Center(child: Text('5km 이내, 10분 이내 요청 없음'));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final doc = filtered[index];
              final map = doc.data() as Map<String, dynamic>;
              final ride = RideRequest.fromMap(map);
              final docId = doc.id;

              final pickup = LatLng(map['pickupLat'], map['pickupLng']);
              final km = distance.as(
                ll.LengthUnit.Kilometer,
                ll.LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
                ll.LatLng(pickup.latitude, pickup.longitude),
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('${ride.pickupPlaceName} ➔ ${ride.destinationName}'),
                  subtitle: Text('승객 ID: ${ride.passengerId}\n거리: ${km.toStringAsFixed(2)} km'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NavigateToPickupPage(
                            driverLocation: _driverLocation!,
                            pickupLocation: pickup,
                            docId: docId,
                          ),
                        ),
                      );
                    },
                    child: const Text('수락'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}