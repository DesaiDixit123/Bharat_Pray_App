import 'package:flutter/foundation.dart';

/// Yatra Temple Model for Group Creation & Routes
@immutable
class YatraTemple {
  final String id;
  final String name;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final String address;
  final String image;

  const YatraTemple({
    required this.id,
    required this.name,
    this.city = '',
    this.state = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.address = '',
    this.image = '',
  });

  factory YatraTemple.fromJson(dynamic rawJson) {
    if (rawJson is! Map) {
      return const YatraTemple(id: '', name: 'Temple');
    }
    final json = Map<String, dynamic>.from(rawJson);
    return YatraTemple(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? 'Temple',
      city: json['city']?.toString() ?? json['location']?['city']?.toString() ?? '',
      state: json['state']?.toString() ?? json['location']?['state']?.toString() ?? '',
      latitude: _parseDouble(json['latitude'] ?? json['lat']),
      longitude: _parseDouble(json['longitude'] ?? json['lng']),
      address: json['address']?.toString() ?? '',
      image: json['image']?.toString() ?? json['thumbnail']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'id': id,
        'name': name,
        'city': city,
        'state': state,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

/// Contact User Model for Group Member Selection
@immutable
class ContactUserModel {
  final String id;
  final String name;
  final String mobile;
  final String profilePic;
  final bool isRegistered;
  final bool isMutualFollower;
  final bool isAlreadyMember;

  const ContactUserModel({
    required this.id,
    required this.name,
    required this.mobile,
    this.profilePic = '',
    this.isRegistered = false,
    this.isMutualFollower = false,
    this.isAlreadyMember = false,
  });

  factory ContactUserModel.fromJson(dynamic rawJson, {bool registered = false}) {
    if (rawJson is! Map) {
      return const ContactUserModel(id: '', name: 'User', mobile: '');
    }
    final json = Map<String, dynamic>.from(rawJson);
    return ContactUserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['fullName']?.toString() ?? 'Devotee',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      profilePic: json['profile_pic']?.toString() ?? json['profilePic']?.toString() ?? '',
      isRegistered: json['is_registered'] == true || registered,
      isMutualFollower: json['isMutualFollower'] == true || json['mutual'] == true,
      isAlreadyMember: json['isAlreadyMember'] == true || json['isMember'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'id': id,
        'name': name,
        'mobile': mobile,
        'profile_pic': profilePic,
        'is_registered': isRegistered,
        'isMutualFollower': isMutualFollower,
        'isAlreadyMember': isAlreadyMember,
      };
}

/// Dynamic Distance Value Wrapper supporting toStringAsFixed(1)
class DistanceNum {
  final double value;

  const DistanceNum(this.value);

  String toStringAsFixed(int fractionDigits) => value.toStringAsFixed(fractionDigits);

  @override
  String toString() => value.toString();
}

/// Group Invitation Model for Invitation Dialogs
@immutable
class GroupInvitationModel {
  final String id;
  final String groupId;
  final String groupName;
  final String groupImage;
  final String inviterName;
  final String templeName;
  final DistanceNum distance;
  final String steps;
  final String status;
  final DateTime? createdAt;

  const GroupInvitationModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    this.groupImage = '',
    this.inviterName = 'Devotee',
    this.templeName = 'Sacred Temple',
    this.distance = const DistanceNum(0.0),
    this.steps = '0 Steps',
    this.status = 'PENDING',
    this.createdAt,
  });

  String get senderName => inviterName;

  factory GroupInvitationModel.fromJson(dynamic rawJson) {
    if (rawJson is! Map) {
      return const GroupInvitationModel(id: '', groupId: '', groupName: 'Group Invitation');
    }
    final json = Map<String, dynamic>.from(rawJson);
    final rawDist = json['distance'] ?? json['totalDistance'];
    final distVal = (rawDist is num) ? rawDist.toDouble() : (double.tryParse(rawDist?.toString() ?? '') ?? 0.0);

    return GroupInvitationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      groupId: json['groupId']?['_id']?.toString() ?? json['groupId']?.toString() ?? '',
      groupName: json['groupId']?['name']?.toString() ?? json['groupName']?.toString() ?? 'Yatra Group',
      groupImage: json['groupId']?['image']?.toString() ?? json['groupImage']?.toString() ?? '',
      inviterName: json['inviterId']?['name']?.toString() ?? json['inviterName']?.toString() ?? json['senderName']?.toString() ?? 'Devotee',
      templeName: json['templeName']?.toString() ?? json['groupId']?['templeName']?.toString() ?? 'Sacred Temple',
      distance: DistanceNum(distVal),
      steps: json['steps']?.toString() ?? '0 Steps',
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'id': id,
        'groupId': groupId,
        'groupName': groupName,
        'groupImage': groupImage,
        'inviterName': inviterName,
        'senderName': inviterName,
        'templeName': templeName,
        'distance': distance.value,
        'steps': steps,
        'status': status,
        'createdAt': createdAt?.toIso8601String(),
      };
}

/// Yatra Group Model for My Groups list
@immutable
class YatraGroupModel {
  final String id;
  final String groupName;
  final String groupImage;
  final String description;
  final String templeName;
  final DistanceNum totalDistance;
  final String estimatedSteps;
  final int memberCount;
  final List<dynamic> members;
  final int maxMembers;
  final String visibility;
  final bool isPublic;
  final String status;
  final DateTime? createdAt;

  const YatraGroupModel({
    required this.id,
    required this.groupName,
    this.groupImage = '',
    this.description = '',
    this.templeName = '',
    this.totalDistance = const DistanceNum(0.0),
    this.estimatedSteps = '0 Steps',
    this.memberCount = 1,
    this.members = const [],
    this.maxMembers = 50,
    this.visibility = 'public',
    this.isPublic = true,
    this.status = 'ACTIVE',
    this.createdAt,
  });

  String get coverImage => groupImage;
  String get name => groupName;

  factory YatraGroupModel.fromJson(dynamic rawJson) {
    if (rawJson is! Map) {
      return const YatraGroupModel(id: '', groupName: 'Yatra Group');
    }
    final json = Map<String, dynamic>.from(rawJson);
    final rawMembers = json['members'];
    final membersList = rawMembers is List ? rawMembers : [];
    final count = membersList.isNotEmpty
        ? membersList.length
        : (_parseInt(json['memberCount'] ?? json['membersCount'], defaultVal: 1));

    final vis = json['visibility']?.toString() ?? (json['isPublic'] == false ? 'private' : 'public');

    final rawDist = json['totalDistance'] ?? json['distance'];
    final distVal = (rawDist is num) ? rawDist.toDouble() : (double.tryParse(rawDist?.toString() ?? '') ?? 0.0);

    return YatraGroupModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      groupName: json['name']?.toString() ?? json['groupName']?.toString() ?? 'Yatra Group',
      groupImage: json['image']?.toString() ?? json['groupImage']?.toString() ?? json['coverImage']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      templeName: json['templeId']?['name']?.toString() ?? json['templeName']?.toString() ?? '',
      totalDistance: DistanceNum(distVal),
      estimatedSteps: json['estimatedSteps']?.toString() ?? json['steps']?.toString() ?? '0 Steps',
      memberCount: count,
      members: membersList,
      maxMembers: _parseInt(json['maxMembers'], defaultVal: 50),
      visibility: vis,
      isPublic: vis == 'public',
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'id': id,
        'groupName': groupName,
        'name': groupName,
        'groupImage': groupImage,
        'coverImage': groupImage,
        'description': description,
        'templeName': templeName,
        'totalDistance': totalDistance.value,
        'estimatedSteps': estimatedSteps,
        'memberCount': memberCount,
        'members': members,
        'maxMembers': maxMembers,
        'visibility': visibility,
        'isPublic': isPublic,
        'status': status,
        'createdAt': createdAt?.toIso8601String(),
      };

  static int _parseInt(dynamic val, {int defaultVal = 0}) {
    if (val == null) return defaultVal;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? defaultVal;
  }
}
