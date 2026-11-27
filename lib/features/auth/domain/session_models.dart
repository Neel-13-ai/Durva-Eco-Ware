class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.displayName,
    required this.roles,
    this.status = 'ACTIVE',
  });

  final String id;
  final String email;
  final String displayName;
  final List<String> roles;
  final String status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'roles': roles,
        'status': status,
      };

  factory UserDto.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final roles = rawRoles is Iterable
        ? rawRoles.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const <String>[];
    return UserDto(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      roles: roles,
      status: (json['status'] ?? 'ACTIVE').toString(),
    );
  }
}

class AuthTokensDto {
  const AuthTokensDto({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}
