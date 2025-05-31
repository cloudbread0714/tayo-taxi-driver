import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'navigate_to_destination_page.dart';

class NavigateToPickupPage extends StatefulWidget {
  final LatLng driverLocation;
  final LatLng pickupLocation;
  final LatLng destinationLocation; // 목적지 좌표 추가
  final String docId;

  const NavigateToPickupPage({
    super.key,
    required this.driverLocation,
    required this.pickupLocation,
    required this.destinationLocation, // 필수 매개변수로 추가
    required this.docId,
  });

  @override
  State<NavigateToPickupPage> createState() => _NavigateToPickupPageState();
}

class _NavigateToPickupPageState extends State<NavigateToPickupPage> {
  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  late LatLng _driver;
  late LatLng _pickup;

  @override
  void initState() {
    super.initState();
    _driver = widget.driverLocation;
    _pickup = widget.pickupLocation;
    _initialize();
  }

  Future<void> _initialize() async {
    final eta = await _getEtaInMinutes(_driver, _pickup);
    final polyline = await _getPolylinePoints(_driver, _pickup);

    if (polyline != null && polyline.isNotEmpty) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: polyline,
          ),
        };
      });
    }

    await _updateRideRequestStatus(eta ?? 10);
  }

  Future<void> _updateRideRequestStatus(int eta) async {
    final rideRequestRef = FirebaseFirestore.instance.collection('ride_requests');
    final currentUser = FirebaseAuth.instance.currentUser;
    final driverId = currentUser?.uid ?? 'unknown';

    final driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(driverId).get();
    final driverName = driverDoc.data()?['name'] ?? '이름 없음';
    final carNumber = driverDoc.data()?['carNumber'] ?? '차량번호 없음';

    final updateData = {
      'status': 'accepted',
      'acceptedAt': Timestamp.now(),
      'estimatedArrivalMinutes': eta,
      'driverId': driverId,
      'driverEmail': currentUser?.email ?? '',
      'driverLat': _driver.latitude,
      'driverLng': _driver.longitude,
      'driverName': driverName,
      'carNumber': carNumber,
    };

    await rideRequestRef.doc(widget.docId).update(updateData);
  }

  Future<void> _markArrivalAtPickup() async {
    final rideRequestRef = FirebaseFirestore.instance.collection('ride_requests');
    await rideRequestRef.doc(widget.docId).update({
      'pickupArrived': true,
      'pickupArrivedAt': Timestamp.now(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("승객 위치에 도착했습니다.")),
      );

      // 목적지 네비게이션 페이지로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NavigationPickupDestinationPage(
            requestId: widget.docId,
            pickupLocation: widget.pickupLocation,
            destinationLocation: widget.destinationLocation,
          ),
        ),
      );
    }
  }

  Future<int?> _getEtaInMinutes(LatLng origin, LatLng destination) async {
    const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final duration = data['routes'][0]['legs'][0]['duration']['value'];
          return (duration / 60).round();
        } else if (data['status'] == 'ZERO_RESULTS') {
          return 3;
        }
      }
    } catch (e) {
      debugPrint('ETA 요청 중 예외 발생: $e');
    }
    return null;
  }

  Future<List<LatLng>?> _getPolylinePoints(LatLng origin, LatLng destination) async {
    const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty &&
            data['routes'][0]['overview_polyline'] != null) {
          final encoded = data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(encoded);
        }
      }
    } catch (e) {
      debugPrint('폴리라인 가져오기 실패: $e');
    }
    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final markers = {
      Marker(markerId: const MarkerId('driver'), position: _driver),
      Marker(markerId: const MarkerId('pickup'), position: _pickup),
    };

    return Scaffold(
      //appBar: AppBar(title: const Text('승객 위치로 이동')),
      body: Column(
        children: [
          const SizedBox(height: 65),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '승객 위치까지 이동 중...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _pickup, zoom: 16),
              onMapCreated: (controller) => _mapController = controller,
              markers: markers,
              polylines: _polylines,
              myLocationEnabled: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _markArrivalAtPickup,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade200),
                child: const Text(
                  ' 승객 위치에 도착 완료',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}