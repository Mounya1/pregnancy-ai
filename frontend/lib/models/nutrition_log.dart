import 'user_profile.dart';

/// Nutrient amounts per typical serving, for a small set of common foods.
/// Values are approximate (rounded, from standard USDA-style references) -
/// good enough for a self-tracking tool, not a substitute for precise
/// nutrition labeling.
class NutrientProfile {
  final double ironMg;
  final double calciumMg;
  final double folateMcg;
  final double proteinG;
  final double vitaminDMcg;

  const NutrientProfile({
    this.ironMg = 0,
    this.calciumMg = 0,
    this.folateMcg = 0,
    this.proteinG = 0,
    this.vitaminDMcg = 0,
  });

  NutrientProfile operator *(int servings) => NutrientProfile(
        ironMg: ironMg * servings,
        calciumMg: calciumMg * servings,
        folateMcg: folateMcg * servings,
        proteinG: proteinG * servings,
        vitaminDMcg: vitaminDMcg * servings,
      );

  NutrientProfile operator +(NutrientProfile other) => NutrientProfile(
        ironMg: ironMg + other.ironMg,
        calciumMg: calciumMg + other.calciumMg,
        folateMcg: folateMcg + other.folateMcg,
        proteinG: proteinG + other.proteinG,
        vitaminDMcg: vitaminDMcg + other.vitaminDMcg,
      );

  /// True when there is anything worth showing. A food that contributes none
  /// of the five tracked nutrients should say so rather than render five
  /// zeroes as if that were a result.
  bool get isEmpty =>
      ironMg == 0 && calciumMg == 0 && folateMcg == 0 && proteinG == 0 && vitaminDMcg == 0;

  Map<String, dynamic> toJson() => {
        'iron_mg': ironMg,
        'calcium_mg': calciumMg,
        'folate_mcg': folateMcg,
        'protein_g': proteinG,
        'vitamin_d_mcg': vitaminDMcg,
      };

  factory NutrientProfile.fromJson(Map<String, dynamic> json) => NutrientProfile(
        ironMg: (json['iron_mg'] as num?)?.toDouble() ?? 0,
        calciumMg: (json['calcium_mg'] as num?)?.toDouble() ?? 0,
        folateMcg: (json['folate_mcg'] as num?)?.toDouble() ?? 0,
        proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
        vitaminDMcg: (json['vitamin_d_mcg'] as num?)?.toDouble() ?? 0,
      );
}

/// A per-serving estimate for a food that is not in [kNutrientDatabase] -
/// typed by hand or read off a photo.
///
/// Mirrors app/schemas.py: NutrientEstimate. [isEstimate] is carried all the
/// way to the UI so a guess is never displayed as a measurement.
class NutrientEstimate {
  const NutrientEstimate({
    required this.foodName,
    required this.perServing,
    this.servingDescription = '1 serving',
    this.note = '',
    this.isEstimate = true,
    this.recognised = true,
  });

  final String foodName;
  final NutrientProfile perServing;
  final String servingDescription;
  final String note;
  final bool isEstimate;

  /// False when the text was not a food at all, so the UI can say that
  /// instead of logging a row of zeroes.
  final bool recognised;

  factory NutrientEstimate.fromJson(Map<String, dynamic> json) => NutrientEstimate(
        foodName: json['food_name'] as String? ?? '',
        perServing: NutrientProfile.fromJson(json),
        servingDescription: json['serving_description'] as String? ?? '1 serving',
        note: json['note'] as String? ?? '',
        isEstimate: json['is_estimate'] as bool? ?? true,
        recognised: json['recognised'] as bool? ?? true,
      );
}

/// A reference set of common foods, searchable in the tracker. Anything not
/// here can still be typed and estimated by the backend.
///
/// Values are rounded from USDA FoodData Central (and India's NIN tables for
/// the Indian dishes, which vary a lot by recipe). Foods with pregnancy
/// cautions - liver (vitamin A), raw or high-mercury fish - are left out on
/// purpose, so the list never reads as a recommendation to eat them.
const Map<String, NutrientProfile> kNutrientDatabase = {
  'Spinach (1 cup cooked)': NutrientProfile(ironMg: 6.4, calciumMg: 245, folateMcg: 263, proteinG: 5.3),
  'Lentils (1 cup cooked)': NutrientProfile(ironMg: 6.6, folateMcg: 358, proteinG: 18),
  'Greek yogurt (1 cup)': NutrientProfile(calciumMg: 300, proteinG: 23, vitaminDMcg: 0.1),
  'Salmon, cooked (3 oz)': NutrientProfile(proteinG: 22, vitaminDMcg: 14.2, ironMg: 0.3),
  'Eggs (2 large)': NutrientProfile(proteinG: 12.6, vitaminDMcg: 1.9, folateMcg: 44),
  'Milk, fortified (1 cup)': NutrientProfile(calciumMg: 300, vitaminDMcg: 2.9, proteinG: 8),
  'Orange (1 medium)': NutrientProfile(folateMcg: 40, calciumMg: 52),
  'Chicken breast, cooked (3 oz)': NutrientProfile(proteinG: 26, ironMg: 0.4),
  'Fortified cereal (1 cup)': NutrientProfile(ironMg: 18, folateMcg: 400),
  'Broccoli (1 cup cooked)': NutrientProfile(calciumMg: 62, folateMcg: 168, ironMg: 1),
  'Almonds (1 oz, ~23)': NutrientProfile(calciumMg: 76, ironMg: 1.1, proteinG: 6),
  'Beef, lean, cooked (3 oz)': NutrientProfile(ironMg: 2.9, proteinG: 25, vitaminDMcg: 0.1),
  'Tofu (1/2 cup)': NutrientProfile(calciumMg: 253, ironMg: 3.4, proteinG: 10),
  'Black beans (1 cup cooked)': NutrientProfile(folateMcg: 256, ironMg: 3.6, proteinG: 15),
  'Avocado (1/2 medium)': NutrientProfile(folateMcg: 60, proteinG: 1.5),

  // Grains and staples
  'Brown rice (1 cup cooked)': NutrientProfile(ironMg: 1, calciumMg: 20, folateMcg: 18, proteinG: 5.5),
  'White rice, enriched (1 cup cooked)': NutrientProfile(ironMg: 1.9, calciumMg: 16, folateMcg: 92, proteinG: 4.3),
  'Quinoa (1 cup cooked)': NutrientProfile(ironMg: 2.8, calciumMg: 31, folateMcg: 78, proteinG: 8.1),
  'Oatmeal (1 cup cooked)': NutrientProfile(ironMg: 2.1, calciumMg: 21, folateMcg: 14, proteinG: 5.9),
  'Whole wheat bread (1 slice)': NutrientProfile(ironMg: 0.8, calciumMg: 50, folateMcg: 15, proteinG: 4),
  'Pasta, enriched (1 cup cooked)': NutrientProfile(ironMg: 1.8, calciumMg: 10, folateMcg: 102, proteinG: 8.1),
  'Roti / chapati, whole wheat (1 medium)': NutrientProfile(ironMg: 0.9, calciumMg: 10, folateMcg: 10, proteinG: 3),
  'Idli (2 pieces)': NutrientProfile(ironMg: 0.6, calciumMg: 10, folateMcg: 10, proteinG: 4),
  'Dosa, plain (1 medium)': NutrientProfile(ironMg: 0.6, calciumMg: 10, folateMcg: 8, proteinG: 3),
  'Poha (1 cup cooked)': NutrientProfile(ironMg: 2.7, calciumMg: 10, folateMcg: 8, proteinG: 3),

  // Beans, lentils and soy
  'Chickpeas / chana (1 cup cooked)': NutrientProfile(ironMg: 4.7, calciumMg: 80, folateMcg: 282, proteinG: 14.5),
  'Kidney beans / rajma (1 cup cooked)': NutrientProfile(ironMg: 3.9, calciumMg: 62, folateMcg: 230, proteinG: 15.3),
  'Moong dal (1 cup cooked)': NutrientProfile(ironMg: 2.8, calciumMg: 55, folateMcg: 321, proteinG: 14.2),
  'Toor dal (1 cup cooked)': NutrientProfile(ironMg: 1.9, calciumMg: 72, folateMcg: 185, proteinG: 11.4),
  'Edamame (1 cup)': NutrientProfile(ironMg: 3.5, calciumMg: 98, folateMcg: 482, proteinG: 18.5),
  'Tempeh (1/2 cup)': NutrientProfile(ironMg: 2.2, calciumMg: 92, folateMcg: 20, proteinG: 17),
  'Hummus (1/4 cup)': NutrientProfile(ironMg: 1.5, calciumMg: 25, folateMcg: 50, proteinG: 4.8),
  'Peanut butter (2 tbsp)': NutrientProfile(ironMg: 0.6, calciumMg: 15, folateMcg: 24, proteinG: 7),

  // Dairy and alternatives
  'Paneer (100 g)': NutrientProfile(ironMg: 0.2, calciumMg: 208, proteinG: 18.3),
  'Plain yogurt / curd (1 cup)': NutrientProfile(calciumMg: 296, folateMcg: 17, proteinG: 8.5, vitaminDMcg: 0.2),
  'Cheddar cheese (1 oz)': NutrientProfile(calciumMg: 200, proteinG: 7, vitaminDMcg: 0.2),
  'Mozzarella, part-skim (1 oz)': NutrientProfile(calciumMg: 222, proteinG: 7),
  'Cottage cheese, low-fat (1 cup)': NutrientProfile(calciumMg: 138, folateMcg: 27, proteinG: 28),
  'Soy milk, fortified (1 cup)': NutrientProfile(ironMg: 1.1, calciumMg: 300, folateMcg: 24, proteinG: 7, vitaminDMcg: 2.9),
  'Almond milk, fortified (1 cup)': NutrientProfile(calciumMg: 450, proteinG: 1, vitaminDMcg: 2.4),
  'Orange juice, fortified (1 cup)': NutrientProfile(calciumMg: 349, folateMcg: 74, proteinG: 1.7, vitaminDMcg: 2.5),

  // Meat, poultry and fish (all cooked)
  'Chicken thigh, cooked (3 oz)': NutrientProfile(ironMg: 1.1, proteinG: 21),
  'Turkey, cooked (3 oz)': NutrientProfile(ironMg: 1.3, proteinG: 25),
  'Lamb / mutton, cooked (3 oz)': NutrientProfile(ironMg: 1.6, proteinG: 22),
  'Sardines, canned (3 oz)': NutrientProfile(ironMg: 2.5, calciumMg: 325, proteinG: 21, vitaminDMcg: 4.1),
  'Tuna, canned light (3 oz)': NutrientProfile(ironMg: 1.3, proteinG: 20, vitaminDMcg: 1),
  'Trout, cooked (3 oz)': NutrientProfile(ironMg: 0.3, proteinG: 20, vitaminDMcg: 16.2),
  'Cod, cooked (3 oz)': NutrientProfile(ironMg: 0.4, proteinG: 19, vitaminDMcg: 1),
  'Shrimp, cooked (3 oz)': NutrientProfile(ironMg: 0.3, calciumMg: 77, proteinG: 20, vitaminDMcg: 0.1),

  // Vegetables (cooked unless noted)
  'Kale (1 cup cooked)': NutrientProfile(ironMg: 1.2, calciumMg: 177, folateMcg: 17, proteinG: 3.5),
  'Collard greens (1 cup cooked)': NutrientProfile(ironMg: 2.2, calciumMg: 268, folateMcg: 177, proteinG: 5),
  'Bok choy (1 cup cooked)': NutrientProfile(ironMg: 1.8, calciumMg: 158, folateMcg: 70, proteinG: 2.7),
  'Asparagus (6 spears)': NutrientProfile(ironMg: 0.8, calciumMg: 21, folateMcg: 134, proteinG: 2.2),
  'Brussels sprouts (1 cup cooked)': NutrientProfile(ironMg: 1.9, calciumMg: 56, folateMcg: 78, proteinG: 4),
  'Green peas (1 cup cooked)': NutrientProfile(ironMg: 2.5, calciumMg: 43, folateMcg: 101, proteinG: 8.6),
  'Okra / bhindi (1 cup cooked)': NutrientProfile(ironMg: 0.4, calciumMg: 123, folateMcg: 74, proteinG: 3),
  'Cauliflower (1 cup cooked)': NutrientProfile(ironMg: 0.4, calciumMg: 20, folateMcg: 55, proteinG: 2.3),
  'Beets (1/2 cup cooked)': NutrientProfile(ironMg: 0.7, calciumMg: 14, folateMcg: 68, proteinG: 1.4),
  'Sweet potato, baked (1 medium)': NutrientProfile(ironMg: 0.8, calciumMg: 43, folateMcg: 7, proteinG: 2),
  'Potato, baked with skin (1 medium)': NutrientProfile(ironMg: 1.9, calciumMg: 26, folateMcg: 45, proteinG: 4.3),
  'Mushrooms, UV-exposed (1/2 cup)': NutrientProfile(ironMg: 0.2, proteinG: 1.5, vitaminDMcg: 9.2),
  'Carrot, raw (1 medium)': NutrientProfile(ironMg: 0.2, calciumMg: 20, folateMcg: 12, proteinG: 0.6),
  'Tomato, raw (1 medium)': NutrientProfile(ironMg: 0.3, calciumMg: 12, folateMcg: 18, proteinG: 1.1),

  // Fruit
  'Banana (1 medium)': NutrientProfile(ironMg: 0.3, calciumMg: 6, folateMcg: 24, proteinG: 1.3),
  'Apple (1 medium)': NutrientProfile(ironMg: 0.2, calciumMg: 11, folateMcg: 5, proteinG: 0.5),
  'Strawberries (1 cup)': NutrientProfile(ironMg: 0.6, calciumMg: 24, folateMcg: 36, proteinG: 1),
  'Mango (1 cup)': NutrientProfile(ironMg: 0.3, calciumMg: 18, folateMcg: 71, proteinG: 1.4),
  'Guava (1 fruit)': NutrientProfile(ironMg: 0.1, calciumMg: 10, folateMcg: 27, proteinG: 1.4),
  'Kiwi (1 medium)': NutrientProfile(ironMg: 0.2, calciumMg: 23, folateMcg: 17, proteinG: 0.8),
  'Pomegranate seeds (1/2 cup)': NutrientProfile(ironMg: 0.3, calciumMg: 9, folateMcg: 33, proteinG: 1.4),
  'Dates, medjool (3)': NutrientProfile(ironMg: 0.7, calciumMg: 46, folateMcg: 11, proteinG: 1.3),
  'Dried apricots (1/4 cup)': NutrientProfile(ironMg: 0.9, calciumMg: 18, folateMcg: 3, proteinG: 1.1),
  'Dried figs (4)': NutrientProfile(ironMg: 0.7, calciumMg: 55, folateMcg: 3, proteinG: 1),
  'Raisins (1/4 cup)': NutrientProfile(ironMg: 0.8, calciumMg: 20, folateMcg: 2, proteinG: 1.2),

  // Nuts and seeds
  'Walnuts (1 oz)': NutrientProfile(ironMg: 0.8, calciumMg: 28, folateMcg: 28, proteinG: 4.3),
  'Cashews (1 oz)': NutrientProfile(ironMg: 1.9, calciumMg: 10, folateMcg: 7, proteinG: 5.2),
  'Chia seeds (2 tbsp)': NutrientProfile(ironMg: 2.2, calciumMg: 179, folateMcg: 13, proteinG: 4.7),
  'Pumpkin seeds (1 oz)': NutrientProfile(ironMg: 2.3, calciumMg: 13, folateMcg: 16, proteinG: 8.5),
  'Sunflower seeds (1 oz)': NutrientProfile(ironMg: 1.5, calciumMg: 22, folateMcg: 67, proteinG: 5.5),
  'Sesame seeds (1 tbsp)': NutrientProfile(ironMg: 1.3, calciumMg: 88, folateMcg: 9, proteinG: 1.6),
  'Tahini (1 tbsp)': NutrientProfile(ironMg: 1.3, calciumMg: 64, folateMcg: 15, proteinG: 2.6),
  'Flaxseed, ground (1 tbsp)': NutrientProfile(ironMg: 0.4, calciumMg: 18, folateMcg: 6, proteinG: 1.3),

  // Other
  'Blackstrap molasses (1 tbsp)': NutrientProfile(ironMg: 3.6, calciumMg: 172),
};

/// Daily RDA-style targets by life stage. Pregnancy and breastfeeding values
/// are elevated versions of general adult female targets - approximate,
/// intended for self-tracking motivation, not clinical precision.
///
/// [gender] only matters in General mode, where an adult man's targets
/// differ: 8mg iron (no menstrual losses) and 56g protein (NIH, ages 19-50).
/// Unspecified keeps the female values - the higher iron target is the safer
/// one to aim for when we do not know.
NutrientProfile targetsForLifeStage(LifeStage stage, [Gender gender = Gender.unspecified]) {
  switch (stage) {
    case LifeStage.pregnancy:
      return const NutrientProfile(ironMg: 27, calciumMg: 1000, folateMcg: 600, proteinG: 71, vitaminDMcg: 15);
    case LifeStage.breastfeeding:
      return const NutrientProfile(ironMg: 9, calciumMg: 1000, folateMcg: 500, proteinG: 71, vitaminDMcg: 15);
    case LifeStage.general when gender == Gender.male:
      return const NutrientProfile(ironMg: 8, calciumMg: 1000, folateMcg: 400, proteinG: 56, vitaminDMcg: 15);
    case LifeStage.postpartum:
    case LifeStage.general:
      return const NutrientProfile(ironMg: 18, calciumMg: 1000, folateMcg: 400, proteinG: 46, vitaminDMcg: 15);
  }
}

NutrientProfile targetsForProfile(UserProfile profile) =>
    targetsForLifeStage(profile.lifeStage, profile.gender);

/// How the entry got into the log. Only used for wording and an icon, but
/// the difference matters: a value looked up in the built-in table is exact,
/// and one estimated from a name or a photo is not.
enum NutritionSource { picked, typed, scanned }

NutritionSource nutritionSourceFromString(String? value) =>
    NutritionSource.values.firstWhere(
      (s) => s.name == value,
      orElse: () => NutritionSource.picked,
    );

class NutritionEntry {
  final String id;
  final String foodName;
  final int servings;
  final DateTime loggedAt;

  /// Nutrients for ONE serving, carried on the entry itself.
  ///
  /// Null for foods that came from [kNutrientDatabase], which stays the
  /// source of truth for those. Anything typed or scanned has no table entry
  /// to look up later, so its numbers have to live here or they are lost.
  final NutrientProfile? perServing;

  /// What one serving means for this food, e.g. "1 cup cooked (180g)". Null
  /// for built-in foods, whose names already carry the serving.
  final String? servingDescription;

  final NutritionSource source;

  NutritionEntry({
    required this.id,
    required this.foodName,
    required this.servings,
    DateTime? loggedAt,
    this.perServing,
    this.servingDescription,
    this.source = NutritionSource.picked,
  }) : loggedAt = loggedAt ?? DateTime.now();

  NutrientProfile get nutrients =>
      (perServing ?? kNutrientDatabase[foodName] ?? const NutrientProfile()) * servings;

  /// False when nothing is known about this food - it still belongs in the
  /// log as a record of what was eaten, but it must not silently count as
  /// zero towards the day's targets without saying so.
  bool get hasNutrients =>
      perServing != null || kNutrientDatabase.containsKey(foodName);

  /// Estimated values are never presented as measured ones.
  bool get isEstimated => source != NutritionSource.picked;

  Map<String, dynamic> toJson() => {
        'id': id,
        'food_name': foodName,
        'servings': servings,
        'logged_at': loggedAt.toIso8601String(),
        if (perServing != null) 'per_serving': perServing!.toJson(),
        if (servingDescription != null) 'serving_description': servingDescription,
        'source': source.name,
      };

  factory NutritionEntry.fromJson(Map<String, dynamic> json) => NutritionEntry(
        id: json['id'] as String,
        foodName: json['food_name'] as String,
        servings: json['servings'] as int,
        loggedAt: DateTime.tryParse(json['logged_at'] as String? ?? '') ?? DateTime.now(),
        // Absent on entries written before foods could be typed or scanned;
        // those all came from the built-in table, so the lookup still works.
        perServing: json['per_serving'] == null
            ? null
            : NutrientProfile.fromJson(json['per_serving'] as Map<String, dynamic>),
        servingDescription: json['serving_description'] as String?,
        source: nutritionSourceFromString(json['source'] as String?),
      );

  bool isSameDay(DateTime day) =>
      loggedAt.year == day.year && loggedAt.month == day.month && loggedAt.day == day.day;
}
