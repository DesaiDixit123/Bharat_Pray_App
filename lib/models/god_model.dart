import '../services/api_service.dart';

class GodModel {
  final String id;
  final String name;
  final String slug;
  final String image;
  final String mantra;
  final String description;
  final bool status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GodModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.image = '',
    this.mantra = '',
    this.description = '',
    this.status = true,
    this.createdAt,
    this.updatedAt,
  });

  factory GodModel.fromJson(Map<String, dynamic> json) {
    return GodModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      image: ApiService.resolveImageUrl(json['image']?.toString()),
      mantra: json['mantra']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status'] == true || json['status'] == 'true',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'slug': slug,
      'image': image,
      'mantra': mantra,
      'description': description,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
