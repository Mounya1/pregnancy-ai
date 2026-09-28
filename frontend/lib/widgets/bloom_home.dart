import 'package:flutter/material.dart';

import '../models/pregnancy_week.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import 'stage_figure.dart';
import 'ui/app_card.dart';

/// The Bloom landing layout: a masthead, a display-type hero, a row of
/// summary cards, and a dark band for the assistant.
///
/// These are the pieces that only make sense above phone width, so each one
/// reshapes rather than shrinks - the hero stacks, the card row becomes a
/// column, and the dark band drops its illustration. Nothing here scales a
/// desktop layout down; a phone gets a layout built for a phone.

// ---------------------------------------------------------------- masthead

/// Logo, wordmark, and the week pill. The nav pills only appear on wide
/// screens, where there is room for them and no bottom bar doing the same job.
class BloomMasthead extends StatelessWidget {
  const BloomMasthead({
    super.key,
    required this.profile,
    required this.onAskBloom,
    required this.onWeekTap,
    required this.onNav,
  });

  final UserProfile profile;
  final VoidCallback onAskBloom;
  final VoidCallback onWeekTap;

  /// Index into the app's tabs, so the nav group drives the same destinations
  /// the bottom bar does on a phone rather than becoming a second router.
  final ValueChanged<int> onNav;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _build(context, constraints.maxWidth),
    );
  }

  /// Laid out against the width actually available, not the width of the
  /// window.
  ///
  /// The page is capped and guttered, so a 1680 monitor hands this row about
  /// 1080 - and the row's own contents are text whose width depends on the
  /// font that loaded. Deciding from the screen size instead meant the nav
  /// group could be shown into a space that could not hold it, which
  /// overflows rather than degrading.
  Widget _build(BuildContext context, double available) {
    final p = context.palette;
    final week = profile.pregnancyWeek;

    // Everything either side of the nav group needs roughly this much; below
    // it the group is dropped rather than squeezed.
    const roomForNav = 980.0;
    final showNav = context.isWide && available >= roomForNav;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            shape: BoxShape.circle,
            boxShadow: p.softShadow,
          ),
          padding: const EdgeInsets.all(5),
          child: Image.asset(
            'assets/images/logo.png',
            errorBuilder: (_, __, ___) =>
                Icon(Icons.spa_rounded, size: 20, color: p.brand),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Flexible so a long wordmark clips rather than pushing the row past
        // its bounds.
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bloom',
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleLarge,
              ),
              Text(
                'AI pregnancy companion',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: p.textSecondary),
              ),
            ],
          ),
        ),
        // Centred between the wordmark and the actions, which is what the
        // two Spacers buy over a single Expanded on the wordmark.
        const Spacer(),
        if (showNav) ...[
          _NavGroup(onNav: onNav),
          const Spacer(),
        ],
        if (week != null) ...[
          _Pill(
            icon: Icons.calendar_today_rounded,
            // "Week 24 · T2" on wide, just "W24" on a phone - the trimester
            // is already on the hero badge a few pixels below.
            label: context.isCompact
                ? 'W$week'
                : 'Week $week · T${pregnancyWeekInfo(week).trimester}',
            onTap: onWeekTap,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        _AccentPill(label: 'Ask Bloom', onTap: onAskBloom),
      ],
    );
  }
}

/// The centre nav group: one white pill holding several text destinations.
///
/// Wide screens only. On a phone the bottom bar already does this job, and a
/// second row of the same destinations would be noise.
class _NavGroup extends StatelessWidget {
  const _NavGroup({required this.onNav});

  final ValueChanged<int> onNav;

  /// Labels come from the design; the indices are this app's tabs.
  ///
  /// "Symptoms" is the Track tab, which is where logging lives, and
  /// "Assistant" is index -1 - the chat is pushed rather than a tab, so it
  /// cannot be addressed the same way.
  static const _items = [('Overview', 0), ('Symptoms', 2), ('Assistant', -1)];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: p.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, index) in _items)
            Pressable(
              onTap: () => onNav(index),
              scale: 0.95,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: 12,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: p.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: p.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: p.brand),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentPill extends StatelessWidget {
  const _AccentPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: p.accent.withValues(alpha: p.isDark ? 0.28 : 0.34),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- hero

/// The display-type hero: a status badge, a three-colour headline, the week's
/// detail, two calls to action, and the illustration.
class BloomHero extends StatelessWidget {
  const BloomHero({
    super.key,
    required this.profile,
    required this.onPrimary,
    required this.onAsk,
  });

  final UserProfile profile;
  final VoidCallback onPrimary;
  final VoidCallback onAsk;

  bool get _isPregnancy => profile.lifeStage == LifeStage.pregnancy;

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;

    final text = _HeroText(
      profile: profile,
      onPrimary: onPrimary,
      onAsk: onAsk,
      isPregnancy: _isPregnancy,
    );
    final art = _HeroArt(profile: profile);

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          text,
          const SizedBox(height: AppSpacing.xxl),
          art,
        ],
      );
    }

    // 55/40 with a gutter, matching the design - the headline needs the wider
    // share because it is set at display size and must not break mid-phrase.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 55, child: text),
        const SizedBox(width: AppSpacing.xxxl),
        Expanded(flex: 40, child: art),
      ],
    );
  }
}

/// Pregnant while pregnant, mother and baby after the birth, and a man or
/// woman in General mode.
class _HeroArt extends StatelessWidget {
  const _HeroArt({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final image = stageHeroImage(profile);
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: p.border),
        boxShadow: p.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 900 / 756,
        // Contain, not cover: the stage pictures are portrait and this frame
        // is landscape, so cover would crop off heads and feet. The fill
        // matches the pictures' own background so the letterbox is invisible.
        // The landscape pregnancy picture is exactly the frame's shape, so
        // contain changes nothing for it.
        child: ColoredBox(
          color: const Color(0xFFFAF8FD),
          child: Image.asset(
            image,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText({
    required this.profile,
    required this.onPrimary,
    required this.onAsk,
    required this.isPregnancy,
  });

  final UserProfile profile;
  final VoidCallback onPrimary;
  final VoidCallback onAsk;
  final bool isPregnancy;

  /// The headline, split into three runs so each can take its own colour.
  ///
  /// The size comparison is the part people repeat to other people, so it
  /// gets the accent and the last line to itself rather than being folded
  /// into a sentence.
  (String, String, String) _headline(PregnancyWeek? info) {
    if (info != null) {
      return ('Your baby is', 'the size of', '${info.sizeComparison}.');
    }
    return switch (profile.lifeStage) {
      LifeStage.breastfeeding => ('Feeding well,', 'both of you,', 'every day.'),
      LifeStage.postpartum => ('Recovery is', 'its own kind', 'of work.'),
      LifeStage.pregnancy => ('Your pregnancy,', 'answered', 'week by week.'),
      LifeStage.general => ('Eating well,', 'without the', 'second-guessing.'),
    };
  }

  String _body(PregnancyWeek? info) {
    if (info == null) {
      return 'Ask about any food and get an answer grounded in ACOG, CDC, FDA, '
          'NIH and AAP guidance - not a guess.';
    }
    final week = info.week;
    final left = 40 - week;
    final size = [
      if (info.lengthCm != null) 'about ${info.lengthDisplay}',
      if (info.weightGrams != null) info.weightDisplay,
    ].join(' and ');
    return "You're $week weeks along - about $left weeks to go. "
        '${size.isEmpty ? '' : 'Your baby is roughly $size. '}'
        '${info.babyDevelopment}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final week = isPregnancy ? profile.pregnancyWeek : null;
    final info = week == null ? null : pregnancyWeekInfo(week);
    final (a, b, c) = _headline(info);

    // Measured off the design: cap height runs about 70px in a 1280 frame,
    // which puts the face near 84. It is the whole composition - the image
    // beside it is sized to the three lines, not the other way round.
    //
    // Scaled with the viewport rather than stepped, so a 1440 monitor is not
    // showing the same headline as a 1024 laptop with more space around it.
    final w = MediaQuery.sizeOf(context).width;
    final size = switch (context.screen) {
      ScreenSize.wide => (w * 0.066).clamp(74.0, 96.0),
      ScreenSize.medium => 52.0,
      ScreenSize.compact => 38.0,
    };
    final display = context.texts.displayLarge ?? const TextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (info != null) _StatusBadge(info: info),
        if (info != null) const SizedBox(height: AppSpacing.xl),
        RichText(
          text: TextSpan(
            style: display.copyWith(
              fontSize: size,
              // Display type sets tighter and heavier than a heading does.
              // Fraunces carries w900 without muddying, and the leading has
              // to come below 1 or three stacked lines read as three
              // separate headings rather than one sentence.
              height: 0.98,
              fontWeight: FontWeight.w900,
              letterSpacing: size * -0.03,
            ),
            children: [
              TextSpan(text: '$a\n', style: TextStyle(color: p.textPrimary)),
              TextSpan(text: '$b\n', style: TextStyle(color: p.brand)),
              TextSpan(text: c, style: TextStyle(color: p.accent)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Text(
            _body(info),
            style: TextStyle(
              fontSize: context.isCompact ? 14.5 : 18,
              height: 1.7,
              color: p.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _SolidCta(
              label: isPregnancy ? "Log today's symptoms" : 'Log a food',
              onTap: onPrimary,
            ),
            _GhostCta(label: 'Ask Bloom', onTap: onAsk),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.info});

  final PregnancyWeek info;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: p.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: p.safe, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'Week ${info.week} · ${info.trimesterLabel}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolidCta extends StatelessWidget {
  const _SolidCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 19),
        decoration: BoxDecoration(
          color: p.brand,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: p.brandShadow(opacity: 0.3),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: p.onBrand,
          ),
        ),
      ),
    );
  }
}

class _GhostCta extends StatelessWidget {
  const _GhostCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 19),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: p.border),
          boxShadow: p.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 17, color: p.accent),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- card grid

/// A responsive row of equal cards - three across on a monitor, stacked on a
/// phone. Cards are given as builders so each keeps its own height.
class BloomCardGrid extends StatelessWidget {
  const BloomCardGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Three across needs the wide breakpoint, not merely "not a phone". At
    // tablet width the columns come out around 250px, which is narrower than
    // the cards' own content and overflows them vertically.
    if (!context.isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            children[i],
          ],
        ],
      );
    }

    // Top-aligned rather than stretched to a common height. Equal heights
    // need IntrinsicHeight, which throws on any child that cannot report an
    // intrinsic dimension - and these slots hold existing cards containing
    // charts and gradients, not only the purpose-built one below.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.lg),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// A card in the "at a glance" row: tinted circular icon chip, serif heading,
/// body, then whatever the card is actually for.
class BloomGlanceCard extends StatelessWidget {
  const BloomGlanceCard({
    super.key,
    this.icon,
    this.tint,
    required this.title,
    this.body,
    this.child,
    this.actionLabel,
    this.actionNote,
    this.onAction,
    this.headerAction,
  });

  /// Omitted by cards that lead with a header action instead of a chip.
  final IconData? icon;
  final Color? tint;
  final String title;
  final String? body;
  final Widget? child;

  /// The link at the foot of the card, e.g. "Check a food".
  final String? actionLabel;

  /// Muted text trailing the link, e.g. the week it applies to.
  final String? actionNote;
  final VoidCallback? onAction;

  /// A small pill on the title row, e.g. "+ Add".
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chipTint = tint ?? p.brand;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: chipTint.withValues(alpha: p.isDark ? 0.24 : 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 25, color: chipTint),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          Row(
            children: [
              Expanded(child: Text(title, style: context.texts.titleLarge)),
              if (headerAction != null) headerAction!,
            ],
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              body!,
              style:
                  TextStyle(fontSize: 13.5, height: 1.5, color: p.textSecondary),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: AppSpacing.lg),
            child!,
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Pressable(
                  onTap: onAction,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: p.brand,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 15, color: p.brand),
                    ],
                  ),
                ),
                if (actionNote != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Text(
                      actionNote!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: p.textMuted),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A section head: display-face title with a muted subtitle under it, and an
/// optional action sitting opposite.
class BloomSectionHead extends StatelessWidget {
  const BloomSectionHead({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: (context.texts.displayLarge ?? const TextStyle())
                    .copyWith(
                  fontSize: context.isCompact ? 24 : 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 14, color: p.textSecondary),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: AppSpacing.lg),
          action!,
        ],
      ],
    );
  }
}

/// A white pill button with a leading icon, used for section actions.
class BloomQuietButton extends StatelessWidget {
  const BloomQuietButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: p.border),
          boxShadow: p.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: p.brand),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: p.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A status pill, e.g. "On track", tinted by the colour passed in.
class BloomStatusPill extends StatelessWidget {
  const BloomStatusPill({super.key, required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: p.isDark ? 0.24 : 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: tint,
        ),
      ),
    );
  }
}

/// "Growth this week": the week's measurements beside what is developing.
class BloomGrowthCard extends StatelessWidget {
  const BloomGrowthCard({super.key, required this.week, required this.onTap});

  final int week;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final info = pregnancyWeekInfo(week);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Growth this week', style: context.texts.titleLarge),
              ),
              BloomStatusPill(label: 'On track', tint: p.safe),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _Measure(
                  value: info.lengthDisplay,
                  label: info.lengthLabel,
                ),
              ),
              Container(width: 1, height: 38, color: p.border),
              Expanded(
                child: _Measure(value: info.weightDisplay, label: 'weight'),
              ),
              Container(width: 1, height: 38, color: p.border),
              Expanded(
                child: _Measure(value: '${40 - week}', label: 'weeks to go'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            info.babyDevelopment,
            style: TextStyle(fontSize: 13.5, height: 1.55, color: p.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          // Averages, not this baby. Saying so on the card is the only place
          // it reliably gets read.
          Text(
            'Population averages - only a scan can measure your baby.',
            style: TextStyle(fontSize: 11.5, height: 1.4, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Measure extends StatelessWidget {
  const _Measure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: (context.texts.displayLarge ?? const TextStyle()).copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: p.textMuted),
        ),
      ],
    );
  }
}

/// The inset grey panel a glance card uses for its empty or summary state.
class BloomNote extends StatelessWidget {
  const BloomNote({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: p.textMuted),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: p.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One ticked line in the tips card: coloured check, bold lead-in, then body.
class BloomCheckItem extends StatelessWidget {
  const BloomCheckItem({
    super.key,
    required this.label,
    required this.text,
    required this.tint,
  });

  final String label;
  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_rounded, size: 15, color: tint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: p.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The small pill on a card's title row, e.g. "+ Add".
class BloomHeaderAction extends StatelessWidget {
  const BloomHeaderAction({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: p.accent.withValues(alpha: p.isDark ? 0.24 : 0.13),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 14, color: p.accent),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: p.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- dark band

/// The assistant band: a near-black panel with a sample exchange.
///
/// Deliberately the one dark surface in a light page. The assistant is the
/// thing the app is actually for, and a band that inverts is what stops it
/// reading as the eighth card in a list of cards.
class BloomAssistantBand extends StatelessWidget {
  const BloomAssistantBand({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const ground = Color(0xFF1B1922); // just under Bloom's ink
    final wide = context.isWide;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: const Text(
            'AI ASSISTANT',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Ask Bloom anything,\nany hour.',
          style: (context.texts.displayLarge ?? const TextStyle()).copyWith(
            fontSize: wide ? 36 : 27,
            height: 1.15,
            letterSpacing: -0.8,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            'From "is this safe?" to "what should I eat?" - grounded in your '
            'week and your profile, with clear guidance on when to contact '
            'your care team.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _AccentPill(label: 'Open assistant  →', onTap: onOpen),
      ],
    );

    final preview = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Bubble(
          text: 'My legs feel heavy at night, is that normal?',
          color: p.brand,
          textColor: Colors.white,
          mine: true,
        ),
        const SizedBox(height: AppSpacing.md),
        // The reply is attributed. Without the mark beside it the exchange
        // reads as two people talking rather than someone asking the app.
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 30,
              height: 30,
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF2C2A35),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/logo.png',
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.spa_rounded, size: 15, color: p.brand),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Flexible(
              child: _Bubble(
                text: 'Common as blood volume rises. Try elevation and an '
                    'evening walk. If swelling is sudden or one-sided, '
                    'message your midwife.',
                color: Color(0xFF2C2A35),
                textColor: Colors.white,
                mine: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // A composer that looks like the real one and opens it. Showing the
        // exchange without somewhere to type made the panel read as a
        // screenshot of the app rather than a way into it.
        Pressable(
          onTap: onOpen,
          scale: 0.99,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2A35),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ask about sleep, diet, or symptoms...',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: p.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(wide ? AppSpacing.xxxl : AppSpacing.xl),
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: copy),
                const SizedBox(width: AppSpacing.xxxl),
                Expanded(child: preview),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.xxl),
                preview,
              ],
            ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.color,
    required this.textColor,
    required this.mine,
  });

  final String text;
  final Color color;
  final Color textColor;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 13.5, height: 1.5, color: textColor),
        ),
      ),
    );
  }
}
