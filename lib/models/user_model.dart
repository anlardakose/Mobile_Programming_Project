enum UserRole {
  user,
  admin,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String department;
  final UserRole role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.createdAt,
  });

  // JSON'dan UserModel oluştur
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // createdAt için farklı formatları destekle
    DateTime createdAtDate;
    if (json['createdAt'] is String) {
      createdAtDate = DateTime.parse(json['createdAt'] as String);
    } else if (json['createdAt'] != null) {
      // Firestore Timestamp
      createdAtDate = (json['createdAt'] as dynamic).toDate();
    } else {
      createdAtDate = DateTime.now();
    }

    // role için farklı formatları destekle
    UserRole userRole = UserRole.user;
    if (json['role'] != null) {
      final roleStr = json['role'].toString();
      if (roleStr == 'admin' || roleStr == 'UserRole.admin') {
        userRole = UserRole.admin;
      }
    }

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      department: json['department'] as String? ?? 'Genel',
      role: userRole,
      createdAt: createdAtDate,
    );
  }

  // UserModel'den JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'role': role.toString(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Kopya oluştur (immutability için)
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


