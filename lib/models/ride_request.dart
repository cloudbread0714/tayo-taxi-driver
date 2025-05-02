class RideRequest {
  final String passengerId;
  final String pickupPlaceName;
  final double pickupLat;
  final double pickupLng;
  final String destinationName;
  final double destinationLat;
  final double destinationLng;

  RideRequest({
    required this.passengerId,
    required this.pickupPlaceName,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLng,
  });

  factory RideRequest.fromMap(Map<String, dynamic> map) {
    return RideRequest(
      passengerId: map['passengerId'] ?? '',
      pickupPlaceName: map['pickupPlaceName'] ?? '',
      pickupLat: map['pickupLat']?.toDouble() ?? 0.0,
      pickupLng: map['pickupLng']?.toDouble() ?? 0.0,
      destinationName: map['destinationName'] ?? '',
      destinationLat: map['destinationLat']?.toDouble() ?? 0.0,
      destinationLng: map['destinationLng']?.toDouble() ?? 0.0,
    );
  }
}