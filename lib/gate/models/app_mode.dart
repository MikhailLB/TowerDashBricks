/// Persisted decision about how the app should route on each launch.
///
/// - [web]     → open the WebView (returning user with a saved URL).
/// - [game]    → open the white-part game (organic / unattributed user).
/// - [fresh]   → no decision yet; full attribution pipeline will run.
enum AppMode {
  web,
  game,
  fresh;

  String toKey() {
    switch (this) {
      case AppMode.web:   return 'web';
      case AppMode.game:  return 'game';
      case AppMode.fresh: return 'fresh';
    }
  }

  static AppMode fromKey(String? raw) {
    switch (raw) {
      case 'web':
      case 'browser':
        return AppMode.web;
      case 'game':
      case 'arcade':
        return AppMode.game;
      default:
        return AppMode.fresh;
    }
  }
}
