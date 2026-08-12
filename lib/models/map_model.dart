/// Mirrors app/schemas/map.py -> MapRead on the backend (only the
/// fields the Tournament Details "Info" card needs).
class MapModel {
  final String id;
  final String name;

  MapModel({required this.id, required this.name});

  factory MapModel.fromJson(Map<String, dynamic> json) {
    return MapModel(id: json['id'] as String, name: json['name'] as String);
  }
}
