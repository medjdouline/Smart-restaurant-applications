import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? username;
  final String firstName;
  final String lastName;
  final String role;
  final String? employeeId;
  final String? roleId;
  final String? token;
  final String? uid;
  
  const User({
    required this.id,
    required this.email,
    this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.employeeId,
    this.roleId,
    this.token,
    this.uid,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['uid'] ?? '',
      email: json['email'] ?? '',
      username: json['username'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? '',
      employeeId: json['employee_id'],
      roleId: json['role_id'],
      token: json['token'],
      uid: json['uid'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'employeeId': employeeId,
      'roleId': roleId,
    };
  }
  
  String get fullName => '$firstName $lastName';
  
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? role,
    String? employeeId,
    String? roleId,
    String? token,
    String? uid,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      roleId: roleId ?? this.roleId,
      token: token ?? this.token,
      uid: uid ?? this.uid,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    email,
    username,
    firstName,
    lastName,
    role,
    employeeId,
    roleId,
    uid,
  ];
}