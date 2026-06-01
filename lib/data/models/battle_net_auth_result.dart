class BattleNetAuthResult {
  final String accessToken;

  final String tokenType;

  final int expiresIn;

  const BattleNetAuthResult({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });
}
