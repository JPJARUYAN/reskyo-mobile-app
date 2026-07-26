class BarangayModel {
  final String id;
  final String name;
  final double centroidLat;
  final double centroidLng;

  BarangayModel({
    required this.id,
    required this.name,
    required this.centroidLat,
    required this.centroidLng,
  });

  factory BarangayModel.fromJson(Map<String, dynamic> json) {
    return BarangayModel(
      id: json['id'] as String,
      name: json['name'] as String,
      centroidLat: (json['centroid_lat'] as num).toDouble(),
      centroidLng: (json['centroid_lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'centroid_lat': centroidLat,
      'centroid_lng': centroidLng,
    };
  }
}
