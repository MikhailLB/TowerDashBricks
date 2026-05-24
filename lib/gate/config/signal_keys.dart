import '../../core/mask_util.dart';

/// appsflyerDevKey()       → AppsFlyer Dev Key
/// firebaseProjectNumber() → Firebase Project Number (numeric)
///
/// Run tool/encode_creds.dart to regenerate byte arrays if credentials change.

String appsflyerDevKey() {
  const v = [33, 67, 207, 60, 74, 38, 118, 254, 109, 187, 111, 240, 196, 114, 24, 205, 104, 139, 245, 182, 239, 86];
  return unmask(v);
}

String firebaseProjectNumber() {
  const v = [88, 20, 147, 123, 26, 100, 58, 184, 57, 246, 18];
  return unmask(v);
}
