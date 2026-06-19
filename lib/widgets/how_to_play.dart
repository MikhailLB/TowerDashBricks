import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../game/unit_class.dart';
import 'pixel_button.dart';

/// Full-screen, swipeable tutorial explaining Brick Tactics.
/// Used as a first-run overlay and from the menu's "How to Play".
class HowToPlayOverlay extends StatefulWidget {
  const HowToPlayOverlay({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<HowToPlayOverlay> createState() => _HowToPlayOverlayState();
}

class _HowToPlayOverlayState extends State<HowToPlayOverlay> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = <_Step>[
    _Step(
      icon: Icons.dashboard_customize_rounded,
      title: 'Build Your Tower',
      body:
          'Stack brick-units from your deck onto the tower. The bottom unit is '
          'your front line; units higher up join the fight as the front falls.',
    ),
    _Step(
      icon: Icons.groups_rounded,
      title: 'Six Classes',
      body:
          'Tanks soak hits, Warriors brawl, Archers and Mages snipe the weakest '
          'foe, Healers mend allies, and Bombers hit two enemies at once.',
      sample: _ClassesSample(),
    ),
    _Step(
      icon: Icons.auto_awesome_rounded,
      title: 'Stack Synergies',
      body:
          'Field 3+ units of the same class to trigger a team-wide buff. '
          'Five or more makes it even stronger. Mix wisely!',
    ),
    _Step(
      icon: Icons.emoji_events_rounded,
      title: 'Auto-Battle & Win',
      body:
          'Towers trade blows automatically. Clear the campaign, climb the Arena '
          'leagues, and open crates to collect and upgrade rarer bricks.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _steps.length - 1) {
      widget.onClose();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _steps.length - 1;
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Text('Skip',
                      style: AppTextStyles.body(
                          size: 15, color: AppColors.textMuted)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _steps.length,
                itemBuilder: (_, i) => _StepView(step: _steps[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          i == _page ? AppColors.craneYellow : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
              child: PixelButton(
                label: isLast ? 'Build!' : 'Next',
                onPressed: _next,
                width: double.infinity,
                height: 56,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.icon,
    required this.title,
    required this.body,
    this.sample,
  });
  final IconData icon;
  final String title;
  final String body;
  final Widget? sample;
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.craneYellow.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.craneYellow, width: 2),
              boxShadow: [
                BoxShadow(
                    color: AppColors.craneYellow.withValues(alpha: 0.35),
                    blurRadius: 24)
              ],
            ),
            child: Icon(step.icon, color: AppColors.craneYellow, size: 48),
          ),
          const SizedBox(height: 28),
          Text(step.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title(size: 28)),
          const SizedBox(height: 14),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 16, color: AppColors.textMuted),
          ),
          if (step.sample != null) ...[
            const SizedBox(height: 26),
            step.sample!,
          ],
        ],
      ),
    );
  }
}

/// Shows the six class icons in their suit colors.
class _ClassesSample extends StatelessWidget {
  const _ClassesSample();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final c in UnitClass.values)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.color.withValues(alpha: 0.18),
              border: Border.all(color: c.color, width: 1.5),
            ),
            child: Icon(c.icon, color: c.color, size: 26),
          ),
      ],
    );
  }
}
