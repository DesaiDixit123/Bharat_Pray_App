class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? mobile;
  final String profilePic;
  final String loginType;
  final bool isRegistered;
  final bool status;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.mobile,
    required this.profilePic,
    required this.loginType,
    required this.isRegistered,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      mobile: json['mobile'],
      profilePic: json['profile_pic'] ?? '',
      loginType: json['login_type'] ?? '',
      isRegistered: json['is_registered'] ?? false,
      status: json['status'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'profile_pic': profilePic,
      'login_type': loginType,
      'is_registered': isRegistered,
      'status': status,
    };
  }
}
