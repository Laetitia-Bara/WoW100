import '../config/app_config.dart';

class BattleNetAuthService {
  String buildAuthorizationUrl() {
    const region = 'eu';

    final uri = Uri.https('$region.battle.net', '/oauth/authorize', {
      'client_id': AppConfig.battleNetClientId,
      'redirect_uri': AppConfig.battleNetRedirectUri,
      'response_type': 'code',
      'scope': 'wow.profile',
      'state': 'wow100-dev',
    });

    return uri.toString();
  }
}
