import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class NavigateToPickupPage extends StatefulWidget {
  final LatLng driverLocation;
  final LatLng pickupLocation;
  final String docId;

  const NavigateToPickupPage({
    super.key,
    required this.driverLocation,
    required this.pickupLocation,
    required this.docId,
  });

  @override
  State<NavigateToPickupPage> createState() => _NavigateToPickupPageState();
}

class _NavigateToPickupPageState extends State<NavigateToPickupPage> {
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _updateRideRequestStatus();
  }

  Future<void> _updateRideRequestStatus() async {
    final rideRequestRef = FirebaseFirestore.instance.collection('ride_requests');
    final currentUser = FirebaseAuth.instance.currentUser;

    final eta = await _getEtaInMinutes(widget.driverLocation, widget.pickupLocation);

    await rideRequestRef.doc(widget.docId).update({
      'status': 'accepted',
      'acceptedAt': Timestamp.now(),
      'estimatedArrivalMinutes': eta,
      'driverId': currentUser?.uid ?? 'unknown',
      'driverEmail': currentUser?.email ?? '',
      'driverLat': widget.driverLocation.latitude,
      'driverLng': widget.driverLocation.longitude,
    });
  }

  Future<int?> _getEtaInMinutes(LatLng origin, LatLng destination) async {
    const apiKey = 'AIzaSyAZ0JlE3jDLccPhO6BgoQy3S5WINi8UKKQ'; // 🔒 .env 파일에 저장 권장
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final duration = data['routes'][0]['legs'][0]['duration']['value'];
        return (duration / 60).round();
      } else {
        debugPrint('❌ ETA 요청 실패: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ ETA 요청 중 예외 발생: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = LatLng(widget.driverLocation.latitude, widget.driverLocation.longitude);
    final pickup = LatLng(widget.pickupLocation.latitude, widget.pickupLocation.longitude);

    final markers = {
      Marker(markerId: const MarkerId('driver'), position: driver),
      Marker(markerId: const MarkerId('pickup'), position: pickup),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('승객 위치로 이동')),
      body: SizedBox.expand(
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: pickup, zoom: 14),
          onMapCreated: (controller) => _mapController = controller,
          markers: markers,
          myLocationEnabled: true,
        ),
      ),
    );
  }
}