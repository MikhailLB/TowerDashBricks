import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'pixel_button.dart';

/// Full-screen, swipeable tutorial explaining the nonogram rules.
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
      icon: Icons.tag_rounded,
      title: 'Read the Blueprint',
      body:
          'Numbers next to each row and column tell you the runs of bricks — '
          'how many bricks sit together in a line, in order.',
      sample: _ClueSample(),
    ),
    _Step(
      icon: Icons.add_box_rounded,
      title: 'Lay Bricks',
      body:
          'Tap a cell to lay a brick where it belongs. Drag your finger across '
          'the grid to lay a whole line quickly.',
    ),
    _Step(
      icon: Icons.close_rounded,
      title: 'Mark the Gaps',
      body:
          'Switch to "Mark Gap" to cross out cells you know are empty. '
          'Marking is free — it never costs a life.',
    ),
    _Step(
      icon: Icons.favorite_rounded,
      title: 'Mind Your Lives',
      body:
          'A misplaced brick costs a heart. Run out and the blueprint is '
          'scrapped. Stuck? Tap the bulb to reveal one correct brick.',
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
      color: Colors.black.withValues(alpha: 0.8),
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
                      color: i == _page
                          ? AppColors.craneYellow
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
              child: PixelButton(
                label: isLast ? "Let's Build" : 'Next',
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
              color: AppColors.craneYellow.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.craneYellow, width: 2),
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

/// A tiny worked example: clue "3 1" → filled pattern ███ ░ █.
class _ClueSample extends StatelessWidget {
  const _ClueSample();

  @override
  Widget build(BuildContext context) {
    const pattern = [true, true, true, false, true];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('3  1',
                style: AppTextStyles.button(
                    size: 18, color: AppColors.craneYellow)),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_rounded,
                color: AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            for (final filled in pattern)
              Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: filled
                      ? AppColors.craneYellow
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white24),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
