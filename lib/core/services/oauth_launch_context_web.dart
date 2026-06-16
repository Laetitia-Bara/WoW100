import 'package:web/web.dart' as web;

void markWebOAuthLaunch() {
  web.window.sessionStorage.setItem('wow100_oauth_launch', 'web');
}
