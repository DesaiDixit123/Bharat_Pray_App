import '../services/api_service.dart';

class YatraModel {
  final String id;
  final String? journeyId;
  final String title;
  final String distance;
  final String steps;
  final String duration;
  final String groupSize;
  final String image;
  final String tag;
  final double progress;
  final List<dynamic>? routeTemples;

  YatraModel({
    required this.id,
    this.journeyId,
    required this.title,
    required this.distance,
    required this.steps,
    required this.duration,
    required this.groupSize,
    required this.image,
    required this.tag,
    required this.progress,
    this.routeTemples,
  });

  factory YatraModel.fromJson(Map<String, dynamic> json) {
    final rawDistance = json['distance'];
    final rawSteps    = json['walkingSteps'] ?? json['steps'];
    final rawDuration = json['duration'];
    final rawGroup    = json['totalUsers'] ?? json['groupSize'];

    final distanceStr = rawDistance != null
        ? '${_formatNum(rawDistance)} KM'
        : (json['distanceStr'] ?? '0 KM');

    final stepsStr = rawSteps != null
        ? '${_formatNum(rawSteps)} Steps'
        : (json['stepsStr'] ?? '0 Steps');

    final durationStr = rawDuration != null
        ? '$rawDuration ${rawDuration == 1 ? "Day" : "Days"}'
        : (json['durationStr'] ?? '0 Days');

    final groupStr = rawGroup != null
        ? _formatNum(rawGroup)
        : (json['groupSizeStr'] ?? '0');

    return YatraModel(
      id: json['_id'] ?? '1',
      journeyId: json['journeyId'],
      title: json['title'] ?? json['name'] ?? 'Yatra',
      distance: distanceStr,
      steps: stepsStr,
      duration: durationStr,
      groupSize: groupStr,
      image: ApiService.resolveImageUrl(json['image'] ?? 'assets/images/somnath_temple_new.png'),
      tag: json['category'] ?? "Popular Yatra",
      progress: (json['progress'] ?? 0.0).toDouble(),
      routeTemples: json['routeTemples'] as List<dynamic>?,
    );
  }

  static String _formatNum(dynamic val) {
    final n = (val is int) ? val.toDouble() : (val as num).toDouble();
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} k';
    return n.toInt().toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'journeyId': journeyId,
      'title': title,
      'distance': distance,
      'steps': steps,
      'duration': duration,
      'groupSize': groupSize,
      'image': image,
      'tag': tag,
      'progress': progress,
    };
  }
}

class YatraTemple {
  final String id;
  final String name;
  final String city;
  final String state;
  final String image;
  final double latitude;
  final double longitude;

  YatraTemple({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.image,
    required this.latitude,
    required this.longitude,
  });

  factory YatraTemple.fromJson(Map<String, dynamic> json) {
    return YatraTemple(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      image: ApiService.resolveImageUrl(json['thumbnailImage'] ?? json['bannerImage'] ?? json['image']),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }
}

class ContactUserModel {
  final String id;
  final String name;
  final String mobile;
  final String profilePic;
  final String city;
  final bool isMutualFollower;
  final bool isAlreadyMember;
  final bool isRegistered;

  ContactUserModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.profilePic,
    required this.city,
    required this.isMutualFollower,
    required this.isAlreadyMember,
    required this.isRegistered,
  });

  factory ContactUserModel.fromJson(Map<String, dynamic> json, {bool registered = true}) {
    return ContactUserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Contact',
      mobile: json['mobile'] ?? '',
      profilePic: ApiService.resolveImageUrl(json['profile_pic'] ?? ''),
      city: json['city'] ?? '',
      isMutualFollower: json['isMutualFollower'] ?? false,
      isAlreadyMember: json['isAlreadyMember'] ?? false,
      isRegistered: registered,
    );
  }
}

class YatraGroupModel {
  final String id;
  final String name;
  final String description;
  final String coverImage;
  final String visibility;
  final double totalDistance;
  final int estimatedSteps;
  final int estimatedDays;
  final int maxMembers;
  final String inviteToken;
  final List<dynamic> members;

  YatraGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImage,
    required this.visibility,
    required this.totalDistance,
    required this.estimatedSteps,
    required this.estimatedDays,
    required this.maxMembers,
    required this.inviteToken,
    required this.members,
  });

  factory YatraGroupModel.fromJson(Map<String, dynamic> json) {
    return YatraGroupModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      coverImage: ApiService.resolveImageUrl(json['coverImage']),
      visibility: json['visibility'] ?? 'public',
      totalDistance: (json['totalDistance'] ?? 0.0).toDouble(),
      estimatedSteps: json['estimatedSteps'] ?? 0,
      estimatedDays: json['estimatedDays'] ?? 0,
      maxMembers: json['maxMembers'] ?? 20,
      inviteToken: json['inviteToken'] ?? '',
      members: json['members'] ?? [],
    );
  }
}

class GroupInvitationModel {
  final String id;
  final String groupId;
  final String groupName;
  final String templeName;
  final String senderName;
  final double distance;
  final int steps;
  final DateTime expireTime;

  GroupInvitationModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.templeName,
    required this.senderName,
    required this.distance,
    required this.steps,
    required this.expireTime,
  });

  factory GroupInvitationModel.fromJson(Map<String, dynamic> json) {
    final grp = json['groupId'];
    final snd = json['senderId'];
    final tmp = grp is Map ? grp['templeId'] : null;

    return GroupInvitationModel(
      id: json['_id'] ?? '',
      groupId: grp is Map ? (grp['_id'] ?? '') : (grp ?? ''),
      groupName: grp is Map ? (grp['name'] ?? '') : 'Yatra Group',
      templeName: tmp is Map ? (tmp['name'] ?? '') : 'Selected Temple',
      senderName: snd is Map ? (snd['name'] ?? '') : 'A User',
      distance: grp is Map ? ((grp['totalDistance'] ?? 0.0).toDouble()) : 0.0,
      steps: grp is Map ? (grp['estimatedSteps'] ?? 0) : 0,
      expireTime: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : DateTime.now().add(const Duration(days: 7)),
    );
  }
}
