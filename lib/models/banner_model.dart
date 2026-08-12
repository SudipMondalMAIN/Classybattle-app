/// Mirrors app/schemas/banner.py -> BannerRead on the backend.
class BannerModel {
  final String id;
  final String imageUrl;
  final String? title;
  final String? redirectLink;
  final int sortOrder;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.redirectLink,
    required this.sortOrder,
    required this.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      title: json['title'] as String?,
      redirectLink: json['redirect_link'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
