import '../config/app_config.dart';

class BattleNetAuthService {
  String buildAuthorizationUrl() {
    const region = 'eu';
    const redirectUri = 'http://localhost:8080/callback';

    final uri = Uri.https('$region.battle.net', '/oauth/authorize', {
      'client_id': AppConfig.battleNetClientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'wow.profile',
    });

    return uri.toString();
  }
}
