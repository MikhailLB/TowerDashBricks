class TdbAssets {
  static const _gameplay = 'assets/gameplay';
  static const _boot = 'assets/boot';

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

  static const splashPortrait = '$_boot/boot_portrait.mp4';
  static const splashLandscape = '$_boot/boot_landscape.mp4';

  static String loadingBar(int state) => '$_boot/boot_pulse_$state.webp';
}
