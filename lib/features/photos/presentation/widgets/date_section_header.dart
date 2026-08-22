import 'package:flutter/material.dart';

/// Cream color already established in the app's design system
/// (see FloatingNavBar.barBgColor) — reused here so the floating date pill
/// and the bottom nav pill feel like one consistent visual language.
const Color kFloatingChipColor = Color(0xFFFFF1E4);
const Color kFloatingChipTextColor = Color(0xFF3C3229);

/// The rounded "Sat, Jun 27" chip that floats above the grid and reflects
/// whichever date group is currently scrolled to the top — NOT a header
/// pinned to its own group. Text is swapped via [ValueListenableBuilder]
/// from outside, so this widget never rebuilds the grid itself.
class FloatingDatePill extends StatelessWidget {
  const FloatingDatePill({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(title),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: kFloatingChipColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: kFloatingChipTextColor,
        ),
      ),
    );
  }
}

/// The separate circular "..." button floating to the side of the date pill.
/// Kept as its own widget/hit-target (not part of the pill) to match the
/// screenshot, and left as a stub callback — wiring it to a real menu
/// (open photo view, select group, etc.) is next task's job.
class FloatingMoreButton extends StatelessWidget {
  const FloatingMoreButton({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kFloatingChipColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.more_vert, color: kFloatingChipTextColor, size: 20),
      ),
    );
  }
}

/// White-to-transparent gradient sitting behind the system status bar so its
/// (dark) icons stay legible over photo thumbnails scrolling underneath —
/// this is the "shadow behind the status bar" from the screenshot. This app's
/// status bar icons are dark-on-light, so the scrim lightens the backdrop
/// rather than darkening it. Purely visual, ignores touches.
class TopStatusBarScrim extends StatelessWidget {
  const TopStatusBarScrim({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    // Fully transparent — no scrim behind the status bar/date pill.
    return IgnorePointer(
      child: SizedBox(height: topInset + 48),
    );
  }
}