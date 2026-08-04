class GranthCategory {
  final String id;
  final String name;
  final String description;
  final String image;
  final int granthCount;
  final bool status;

  GranthCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.granthCount,
    required this.status,
  });

  factory GranthCategory.fromJson(Map<String, dynamic> json) {
    return GranthCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Category',
      description: json['description'] ?? 'No description available.',
      image: json['image'] ?? 'assets/images/other_granths_card.png',
      granthCount: json['granthCount'] ?? 0,
      status: json['status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'granthCount': granthCount,
    };
  }
}