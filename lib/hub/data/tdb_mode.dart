/// Persisted decision about how the app should route on each launch.
///
/// - [web]     → open the WebView (returning user with a saved URL).
/// - [fresh]   → no decision yet; full attribution pipeline will run.
enum TdbMode {
  web,
  game,
  fresh;

  String toKey() {
    switch (this) {
      case TdbMode.web:   return 'web';
      case TdbMode.game:  return 'game';
      case TdbMode.fresh: return 'fresh';
    }
  }

  static TdbMode fromKey(String? raw) {
    switch (raw) {
      case 'web':
      case 'browser':
        return TdbMode.web;
      case 'game':
      case 'arcade':
        return TdbMode.game;
      default:
        return TdbMode.fresh;
    }
  }
}
