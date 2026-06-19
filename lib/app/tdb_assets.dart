/// Central registry of asset paths.
///
/// Splash/loading uses the original promo video + bar frames. Gameplay uses
/// the Tower Dash Bricks construction sprite set in `assets/gameplay/`.
class TdbAssets {
  static const _splash = 'assets/splash';
  static const _gp = 'assets/gameplay';

  static const icon = 'assets/tdb_icon.webp';
  static const gameName = 'assets/tdb_name.webp';

  // Splash (reused as-is)
  static const splashPortrait = '$_splash/9x16_loading_screen.mp4';
  static const splashLandscape = '$_splash/16x9_loading_screen.mp4';
  static String loadingBar(int state) => '$_splash/tdb_bar_$state.webp';

  // Backgrounds
  static const sky = '$_gp/tdb_sky.png';
  static const sky2 = '$_gp/tdb_sky_2.png';
  static const cityBg = '$_gp/tdb_battle_bg_arena.png';
  static const ground = '$_gp/tdb_ground.png';
  static const battleBg = '$_gp/td_battle_bg.png';
  static const arenaBg = '$_gp/tdb_battle_bg_arena.png';

  // Extra generated backgrounds for variety.
  static const bgSunset = '$_gp/bg_sunset.png';
  static const bgNight = '$_gp/bg_night.png';
  static const bgPark = '$_gp/bg_park.png';
  static const bgIndustrial = '$_gp/bg_industrial.png';

  /// Every full-bleed scene background, used to vary the look across screens
  /// and arena matches.
  static const List<String> backgrounds = [
    sky,
    sky2,
    bgSunset,
    bgNight,
    bgPark,
    bgIndustrial,
    battleBg,
  ];

  /// Backgrounds that already include their own ground strip, so the shared
  /// [ground] sprite should not be drawn over them.
  static const List<String> backgroundsWithGround = [
    sky,
    bgPark,
    bgNight,
    battleBg,
    bgIndustrial,
  ];

  // Field pieces
  static const base = '$_gp/tdb_base.png';
  static const towerFrame = '$_gp/tdb_tower_frame.png';
  static const crane = '$_gp/tdb_crane.png';
  static const craneHook = '$_gp/tdb_crane_hook.png';

  // Old Tower Dash Bricks building parts (for the Upgrade mini-game).
  static const shopBase = '$_gp/tdb_shop_base.webp';
  static const cityStrip = '$_gp/tdb_city_strip.webp';
  static const cloud = '$_gp/tdb_cloud.webp';
  static const int buildingFloorCount = 6;
  static String buildingFloor(int i) =>
      '$_gp/tdb_building_0${(i % buildingFloorCount) + 1}.webp';

  // Units (class identity sprite)
  static const unitTank = '$_gp/tdb_unit_tank.png';
  static const unitWarrior = '$_gp/tdb_unit_warrior.png';
  static const unitArcher = '$_gp/tdb_unit_archer.png';
  static const unitMage = '$_gp/tdb_unit_mage.png';
  static const unitHealer = '$_gp/tdb_unit_healer.png';
  static const unitBomber = '$_gp/tdb_unit_bomber.png';
  static const unitGolem = '$_gp/tdb_unit_golem.png';
  static const unitSniper = '$_gp/tdb_unit_sniper.png';

  // Bosses
  static const bossWrecker = '$_gp/tdb_boss_wrecker.png';
  static const bossCrane = '$_gp/tdb_boss_crane.png';
  static const bossForeman = '$_gp/tdb_boss_foreman.png';
}
