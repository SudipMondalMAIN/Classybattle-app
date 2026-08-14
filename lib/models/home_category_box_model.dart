/// Mirrors app/schemas/home_category_box.py -> HomeCategoryBoxRead on the
/// backend. These are the static, 3-per-row tap boxes on the home screen
/// (e.g. "Free Fire Solo", "Free Fire Clash Squad", "Custom Tournament").
enum HomeCategoryBoxType { solo, squad, custom }

HomeCategoryBoxType _boxTypeFromJson(String value) {
  return HomeCategoryBoxType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => HomeCategoryBoxType.custom,
  );
}

class HomeCategoryBoxModel {
  final String id;
  final HomeCategoryBoxType boxType;
  final String? gameId;
  final String bannerUrl;
  final String? title;
  final int sortOrder;
  final bool isActive;

  HomeCategoryBoxModel({
    required this.id,
    required this.boxType,
    this.gameId,
    required this.bannerUrl,
    this.title,
    required this.sortOrder,
    required this.isActive,
  });

  factory HomeCategoryBoxModel.fromJson(Map<String, dynamic> json) {
    return HomeCategoryBoxModel(
      id: json['id'] as String,
      boxType: _boxTypeFromJson(json['box_type'] as String),
      gameId: json['game_id'] as String?,
      bannerUrl: json['banner_url'] as String,
      title: json['title'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
