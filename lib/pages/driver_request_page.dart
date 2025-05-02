import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/ride_request.dart';

class DriverRequestPage extends StatelessWidget {
  const DriverRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rideRequestRef = FirebaseFirestore.instance.collection('ride_requests');

    return Scaffold(
      appBar: AppBar(title: const Text('승차 요청')),
      body: StreamBuilder<QuerySnapshot>(
        stream: rideRequestRef.where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('요청 없음'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final map = docs[index].data() as Map<String, dynamic>;
              final ride = RideRequest.fromMap(map);
              final docId = docs[index].id;

              return Card(
                child: ListTile(
                  title: Text('${ride.pickupPlaceName} ➜ ${ride.destinationName}'),
                  subtitle: Text('승객: ${ride.passengerId}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await rideRequestRef.doc(docId).update({
                        'status': 'accepted',
                        'driverId': 'DRIVER_001', // 실제 로그인된 기사 ID로 대체
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