import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import 'ui/illustrations.dart';

/// The figure that matches where the user actually is.
///
/// Pregnant while pregnant, holding the baby once the baby is here, and a
/// plain man or woman in General mode - someone using the app for their own
/// nutrition should not be shown a pregnancy they do not have.
class StageFigure extends StatelessWidget {
  const StageFigure({
    super.key,
    required this.profile,
    required this.color,
    this.size = 120,
    this.accent,
    this.tones,
  });

  final UserProfile profile;
  final Color color;
  final double size;
  final Color? accent;
  final FigureTones? tones;

  @override
  Widget build(BuildContext context) {
    // General first: a birth date left over from an earlier stage should not
    // put a baby back in the picture once the user has switched to General.
    if (profile.lifeStage == LifeStage.general) {
      return PersonIllustration(
        color: color,
        accent: accent,
        tones: tones,
        size: size,
        male: profile.gender == Gender.male,
      );
    }
    if (profile.isAfterBirth) {
      return HoldingBabyIllustration(color: color, accent: accent, tones: tones, size: size);
    }
    return MotherIllustration(color: color, accent: accent, tones: tones, size: size);
  }
}

/// The hero picture for the home page, by stage. "Prefer not to say" gets the
/// woman, matching the female targets that setting uses.
String stageHeroImage(UserProfile profile) {
  switch (profile.lifeStage) {
    case LifeStage.pregnancy:
      return 'assets/images/hero_pregnancy.jpg';
    case LifeStage.breastfeeding:
    case LifeStage.postpartum:
      return 'assets/images/mother_holding_baby.png';
    case LifeStage.general:
      return profile.gender == Gender.male
          ? 'assets/images/general_man.png'
          : 'assets/images/general_woman.png';
  }
}
