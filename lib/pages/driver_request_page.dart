import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../models/ride_request.dart';

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
    final Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, _driverLocation!, pickup) <= radiusKm;
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
      appBar: AppBar(title: const Text('주변 승차 요청')),
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

          final filtered = docs.where((doc) {
            final map = doc.data() as Map<String, dynamic>;
            final pickupLat = map['pickupLat'];
            final pickupLng = map['pickupLng'];

            if (pickupLat == null || pickupLng == null) return false;

            final pickup = LatLng(pickupLat.toDouble(), pickupLng.toDouble());
            return _isWithinRadius(pickup, 5.0);
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('5km 이내 요청 없음'));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final doc = filtered[index];
              final map = doc.data() as Map<String, dynamic>;
              final ride = RideRequest.fromMap(map);
              final docId = doc.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('${ride.pickupPlaceName} ➜ ${ride.destinationName}'),
                  subtitle: Text('승객 ID: ${ride.passengerId}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await rideRequestRef.doc(docId).update({
                        'status': 'accepted',
                        'driverId': 'DRIVER_001',
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('요청 수락 완료')),
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