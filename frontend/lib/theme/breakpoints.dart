import 'package:flutter/widgets.dart';

/// Where the layout changes shape.
///
/// The app was written for a phone and deployed to the web, so every screen
/// rendered as one narrow column stretched across a monitor. These are the
/// two widths at which that stops being the right answer.
///
/// [wide] is where a hero can put its text and its image side by side, and
/// where a row of cards has room to sit in three columns. [medium] is the
/// tablet step between: two columns, but the hero still stacks.
class Breakpoints {
  const Breakpoints._();

  static const medium = 720.0;
  static const wide = 1000.0;

  /// The widest the content ever gets. Past this the page adds margin rather
  /// than line length - a 1600px monitor should not mean 1600px of prose,
  /// which is well beyond the ~75 characters a line can stay readable at.
  static const maxContent = 1180.0;
}

enum ScreenSize { compact, medium, wide }

extension ResponsiveContext on BuildContext {
  ScreenSize get screen {
    final w = MediaQuery.sizeOf(this).width;
    if (w >= Breakpoints.wide) return ScreenSize.wide;
    if (w >= Breakpoints.medium) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  bool get isWide => screen == ScreenSize.wide;
  bool get isCompact => screen == ScreenSize.compact;

  /// Horizontal page padding. Wider screens get more gutter, not just more
  /// content, so the text block keeps a margin to look into.
  double get pageGutter => switch (screen) {
        ScreenSize.compact => 20.0,
        ScreenSize.medium => 32.0,
        ScreenSize.wide => 48.0,
      };
}

/// Centres a page and caps its width, so content stops growing with the
/// window once it has as much room as it can use.
class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? Breakpoints.maxContent),
        child: child,
      ),
    );
  }
}
