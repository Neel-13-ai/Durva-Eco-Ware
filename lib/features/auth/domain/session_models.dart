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
}

class AuthTokensDto {
  const AuthTokensDto({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}
