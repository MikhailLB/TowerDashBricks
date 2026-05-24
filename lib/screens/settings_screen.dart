import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/pixel_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    progress.addListener(_onChanged);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    progress.removeListener(_onChanged);
    _slideCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1520), Color(0xFF1A2D42), Color(0xFF0D1B2A)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _slideCtrl,
              child: Column(
                children: [
                  _Header(onBack: () {
                    AudioService.instance.playSfx(Sfx.buttonClick);
                    Navigator.of(context).pop();
                  }),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        _SectionLabel('Audio'),
                        const SizedBox(height: 10),
                        _ToggleTile(
                          icon: Icons.music_note_rounded,
                          iconColor: AppColors.craneYellow,
                          title: 'Music',
                          subtitle: 'Background music in menu & gameplay',
                          value: progress.musicEnabled,
                          onChanged: (v) async {
                            await AudioService.instance
                                .playSfx(Sfx.buttonClick);
                            await progress.setMusicEnabled(v);
                          },
                        ),
                        const SizedBox(height: 6),
                        _SliderTile(
                          icon: Icons.volume_up_rounded,
                          iconColor: AppColors.craneYellow,
                          title: 'Music Volume',
                          value: progress.musicVolume,
                          enabled: progress.musicEnabled,
                          onChanged: (v) => progress.setMusicVolume(v),
                        ),
                        const SizedBox(height: 14),
                        _ToggleTile(
                          icon: Icons.graphic_eq_rounded,
                          iconColor: AppColors.accent,
                          title: 'Sound Effects',
                          subtitle: 'Brick drops, impact and UI sounds',
                          value: progress.soundEnabled,
                          onChanged: (v) async {
                            await AudioService.instance
                                .playSfx(Sfx.buttonClick);
                            await progress.setSoundEnabled(v);
                            if (v) AudioService.instance.playSfx(Sfx.buttonClick);
                          },
                        ),
                        const SizedBox(height: 6),
                        _SliderTile(
                          icon: Icons.volume_up_rounded,
                          iconColor: AppColors.accent,
                          title: 'SFX Volume',
                          value: progress.sfxVolume,
                          enabled: progress.soundEnabled,
                          onChanged: (v) => progress.setSfxVolume(v),
                        ),
                        const SizedBox(height: 20),
                        _SectionLabel('Haptics'),
                        const SizedBox(height: 10),
                        _ToggleTile(
                          icon: Icons.vibration_rounded,
                          iconColor: AppColors.success,
                          title: 'Vibration',
                          subtitle: 'Haptic feedback on key actions',
                          value: progress.vibrationEnabled,
                          onChanged: (v) async {
                            await progress.setVibrationEnabled(v);
                            if (v) AudioService.instance.vibrate();
                          },
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: PixelButton(
                      label: 'Save & Close',
                      onPressed: () {
                        AudioService.instance.playSfx(Sfx.buttonClick);
                        Navigator.of(context).pop();
                      },
                      width: double.infinity,
                      height: 58,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _CircleBack(onTap: onBack),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETTINGS',
                style: AppTextStyles.body(size: 10, color: AppColors.craneYellow)
                    .copyWith(letterSpacing: 3.0),
              ),
              Text('Preferences', style: AppTextStyles.title(size: 26)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleBack extends StatelessWidget {
  const _CircleBack({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child:
            const Icon(Icons.arrow_back_rounded, color: AppColors.text, size: 22),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.craneYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: AppTextStyles.body(size: 12, color: AppColors.craneYellow)
              .copyWith(letterSpacing: 2.0, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? iconColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.button(size: 16)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        AppTextStyles.body(size: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: iconColor,
            activeTrackColor: iconColor.withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white12,
            inactiveThumbColor: Colors.white38,
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final activeColor = enabled ? iconColor : Colors.white24;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: activeColor, size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: AppTextStyles.body(
                size: 13,
                color: enabled ? AppColors.textMuted : Colors.white24,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: activeColor,
                inactiveTrackColor: Colors.white12,
                thumbColor: activeColor,
                overlayColor: iconColor.withValues(alpha: 0.15),
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '${(value * 100).round()}',
              textAlign: TextAlign.right,
              style: AppTextStyles.body(
                size: 13,
                color: enabled ? AppColors.text : Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
