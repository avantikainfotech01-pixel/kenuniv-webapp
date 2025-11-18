class UserModel {
  final String id;
  final String name;
  final String mobile;
  final String address;
  final String password;
  final String role;
  final bool active;
  final Map<String, dynamic> permissions;

  UserModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
    required this.password,
    required this.role,
    required this.active,
    required this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      address: json['address'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? '',
      active: json['active'] ?? false,
      permissions: json['permissions'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "mobile": mobile,
      "address": address,
      "password": password,
      "role": role,
      "active": active,
      "permissions": permissions,
    };
  }
}
