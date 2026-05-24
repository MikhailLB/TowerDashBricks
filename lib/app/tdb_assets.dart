class TdbAssets {
  static const _gameplay = 'assets/gameplay';
  static const _splash = 'assets/splash';

  static const sky = '$_gameplay/tdb_sky.webp';
  static const ground = '$_gameplay/tdb_ground.webp';
  static const cloud = '$_gameplay/tdb_cloud.webp';
  static const crane = '$_gameplay/tdb_crane.webp';
  static const cityBg = '$_gameplay/tdb_city_bg.webp';
  static const base = '$_gameplay/tdb_base.webp';

  static const icon = 'assets/tdb_icon.webp';
  static const gameName = 'assets/tdb_name.webp';

  static String brick(int n) =>
      '$_gameplay/tdb_brick_0${n.toString().padLeft(1, '0')}.webp';

  static const allBricks = <String>[
    '$_gameplay/tdb_brick_01.webp',
    '$_gameplay/tdb_brick_02.webp',
    '$_gameplay/tdb_brick_03.webp',
    '$_gameplay/tdb_brick_04.webp',
    '$_gameplay/tdb_brick_05.webp',
    '$_gameplay/tdb_brick_06.webp',
  ];

  static const splashPortrait = '$_splash/9x16_loading_screen.mp4';
  static const splashLandscape = '$_splash/16x9_loading_screen.mp4';

  static String loadingBar(int state) => '$_splash/tdb_bar_$state.webp';
}
