import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

class BattleNetAuthService {
  String buildAuthorizationUrl({bool forceLogin = false}) {
    const region = 'eu';

    final queryParameters = {
      'client_id': AppConfig.battleNetClientId,
      'redirect_uri': AppConfig.battleNetRedirectUri,
      'response_type': 'code',
      'scope': 'wow.profile',
      'state': 'wow100-${DateTime.now().millisecondsSinceEpoch}',
      if (forceLogin) 'prompt': 'login',
    };

    final uri = Uri.https(
      '$region.battle.net',
      '/oauth/authorize',
      queryParameters,
    );

    return uri.toString();
  }

  Future<void> openAuthorization({bool forceLogin = false}) async {
    final uri = Uri.parse(buildAuthorizationUrl(forceLogin: forceLogin));

    final didLaunch = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      webOnlyWindowName: '_self',
    );

    if (!didLaunch) {
      throw Exception('Impossible d’ouvrir la connexion Battle.net.');
    }
  }
}
