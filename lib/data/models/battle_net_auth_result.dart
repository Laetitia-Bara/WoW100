class BattleNetAuthResult {
  final String accessToken;

  final String tokenType;

  final int expiresIn;

  const BattleNetAuthResult({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory BattleNetAuthResult.fromJson(Map<String, dynamic> json) {
    return BattleNetAuthResult(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int? ?? 3600,
    );
  }
}
