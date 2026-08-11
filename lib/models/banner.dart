class PromoBanner {
  final String id;
  final String imageUrl;
  final String? title;
  final String? redirectLink;
  final int sortOrder;
  final bool isActive;

  PromoBanner({
    required this.id,
    required this.imageUrl,
    this.title,
    this.redirectLink,
    required this.sortOrder,
    required this.isActive,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: json['id'].toString(),
      imageUrl: json['image_url'] as String,
      title: json['title'] as String?,
      redirectLink: json['redirect_link'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
