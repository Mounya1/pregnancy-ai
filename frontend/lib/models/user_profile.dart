enum LifeStage { pregnancy, breastfeeding, postpartum, general }

/// Optional. Drives the app's colour after the birth, so "not said" has to be
/// a real state rather than defaulting to one of the two.
enum BabyGender { girl, boy, unspecified }

BabyGender babyGenderFromString(String? value) {
  switch (value) {
    case 'girl':
      return BabyGender.girl;
    case 'boy':
      return BabyGender.boy;
    default:
      return BabyGender.unspecified;
  }
}

String babyGenderLabel(BabyGender g) {
  switch (g) {
    case BabyGender.girl:
      return 'Girl';
    case BabyGender.boy:
      return 'Boy';
    case BabyGender.unspecified:
      return 'Prefer not to say';
  }
}

/// The user's own gender. Only asked for in General mode, where it sets the
/// daily targets (men need less iron and more protein) and the figure shown.
/// Every other stage implies a woman, so it is ignored there.
enum Gender { female, male, unspecified }

Gender genderFromString(String? value) {
  switch (value) {
    case 'female':
      return Gender.female;
    case 'male':
      return Gender.male;
    default:
      return Gender.unspecified;
  }
}

String genderLabel(Gender g) {
  switch (g) {
    case Gender.female:
      return 'Woman';
    case Gender.male:
      return 'Man';
    case Gender.unspecified:
      return 'Prefer not to say';
  }
}

/// Languages the AI can answer in, by English name - the backend passes the
/// name straight to the model. Offered as a fixed list so every choice is
/// one the model writes well.
const kAnswerLanguages = [
  'English',
  'Hindi',
  'Telugu',
  'Tamil',
  'Kannada',
  'Marathi',
  'Bengali',
  'Spanish',
  'French',
  'Portuguese',
  'Arabic',
  'Chinese',
];

String lifeStageToApiString(LifeStage s) {
  switch (s) {
    case LifeStage.pregnancy:
      return 'pregnancy';
    case LifeStage.breastfeeding:
      return 'breastfeeding';
    case LifeStage.postpartum:
      return 'postpartum';
    case LifeStage.general:
      return 'general';
  }
}

LifeStage lifeStageFromString(String? value) {
  switch (value) {
    case 'pregnancy':
      return LifeStage.pregnancy;
    case 'breastfeeding':
      return LifeStage.breastfeeding;
    case 'postpartum':
      return LifeStage.postpartum;
    default:
      return LifeStage.general;
  }
}

String lifeStageLabel(LifeStage s) {
  switch (s) {
    case LifeStage.pregnancy:
      return 'Pregnant';
    case LifeStage.breastfeeding:
      return 'Breastfeeding';
    case LifeStage.postpartum:
      return 'Postpartum';
    case LifeStage.general:
      return 'General';
  }
}

/// Whole days from [from]'s date to [to]'s date.
///
/// Both are flattened to a date and compared in UTC. Subtracting the raw
/// DateTimes instead would be wrong twice over: `inDays` truncates, so a due
/// date at midnight reads one day closer than it is for the whole afternoon,
/// and a daylight-saving change makes a 7-day gap measure 6 days 23 hours.
int calendarDaysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// Mirrors app/schemas.py: UserProfile, plus dueDate/babyBirthDate so the
/// user sets a date once (in the Profile screen) instead of updating a
/// week/month number manually - mirrors the backend's date_helpers.py logic.
class UserProfile {
  LifeStage lifeStage;
  DateTime? dueDate;
  DateTime? babyBirthDate;
  List<String> allergies;
  List<String> dietaryPreferences;

  /// Cuisines the meal planner should cook in, e.g. Indian, Chinese.
  /// Empty means no preference - the planner stays international.
  List<String> cuisines;

  /// Conditions the diet has to account for, e.g. gestational diabetes.
  /// Filled in from an uploaded medical report, or edited by hand.
  List<String> healthConditions;

  /// Baby's gender, once known. Only used for the app's colour after birth.
  BabyGender babyGender;

  /// The user's own gender. See [Gender].
  Gender gender;

  /// Language the AI answers in. Only the AI's replies change - the app's
  /// own labels stay in English.
  String language;

  UserProfile({
    this.lifeStage = LifeStage.general,
    this.dueDate,
    this.babyBirthDate,
    this.allergies = const [],
    this.dietaryPreferences = const [],
    this.cuisines = const [],
    this.healthConditions = const [],
    this.babyGender = BabyGender.unspecified,
    this.gender = Gender.unspecified,
    this.language = 'English',
  });

  /// The gender that actually applies: whatever was picked in General mode,
  /// and a woman in every pregnancy or postpartum stage.
  Gender get effectiveGender => lifeStage == LifeStage.general ? gender : Gender.female;

  /// After the birth, so the figure is a mother holding her baby rather than
  /// a pregnant one.
  bool get isAfterBirth =>
      lifeStage == LifeStage.breastfeeding || lifeStage == LifeStage.postpartum;

  /// Standard pregnancy is ~40 weeks; count backward from the due date.
  int? get pregnancyWeek {
    if (dueDate == null) return null;
    final weeksRemaining = calendarDaysBetween(DateTime.now(), dueDate!) ~/ 7;
    return (40 - weeksRemaining).clamp(1, 42);
  }

  int? get babyAgeMonths {
    if (babyBirthDate == null) return null;
    final now = DateTime.now();
    var months = (now.year - babyBirthDate!.year) * 12 + (now.month - babyBirthDate!.month);
    if (now.day < babyBirthDate!.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  Map<String, dynamic> toApiJson() => {
        'life_stage': lifeStageToApiString(lifeStage),
        'pregnancy_week': pregnancyWeek,
        'baby_age_months': babyAgeMonths,
        'allergies': allergies,
        'dietary_preferences': dietaryPreferences,
        'cuisines': cuisines,
        'health_conditions': healthConditions,
        'gender': effectiveGender.name,
        'language': language,
      };

  Map<String, dynamic> toStorageJson() => {
        'life_stage': lifeStageToApiString(lifeStage),
        'due_date': dueDate?.toIso8601String(),
        'baby_birth_date': babyBirthDate?.toIso8601String(),
        'allergies': allergies,
        'dietary_preferences': dietaryPreferences,
        'cuisines': cuisines,
        'health_conditions': healthConditions,
        'baby_gender': babyGender.name,
        'gender': gender.name,
        'language': language,
      };

  factory UserProfile.fromStorageJson(Map<String, dynamic> json) {
    return UserProfile(
      lifeStage: lifeStageFromString(json['life_stage'] as String?),
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      babyBirthDate:
          json['baby_birth_date'] != null ? DateTime.tryParse(json['baby_birth_date'] as String) : null,
      allergies: List<String>.from(json['allergies'] ?? const []),
      dietaryPreferences: List<String>.from(json['dietary_preferences'] ?? const []),
      cuisines: List<String>.from(json['cuisines'] ?? const []),
      healthConditions: List<String>.from(json['health_conditions'] ?? const []),
      babyGender: babyGenderFromString(json['baby_gender'] as String?),
      gender: genderFromString(json['gender'] as String?),
      language: kAnswerLanguages.contains(json['language']) ? json['language'] as String : 'English',
    );
  }

  /// Short label for the home screen header, e.g. "20 weeks pregnant"
  /// or "Breastfeeding, baby 7 months".
  String get statusLabel {
    switch (lifeStage) {
      case LifeStage.pregnancy:
        return pregnancyWeek != null ? '$pregnancyWeek weeks pregnant' : 'Pregnancy';
      case LifeStage.breastfeeding:
        return babyAgeMonths != null
            ? 'Breastfeeding, baby $babyAgeMonths months'
            : 'Breastfeeding';
      case LifeStage.postpartum:
        return 'Postpartum';
      case LifeStage.general:
        return 'General nutrition';
    }
  }

  UserProfile copyWith({
    LifeStage? lifeStage,
    DateTime? dueDate,
    DateTime? babyBirthDate,
    List<String>? allergies,
    List<String>? dietaryPreferences,
    List<String>? cuisines,
    List<String>? healthConditions,
    BabyGender? babyGender,
    Gender? gender,
    String? language,
  }) {
    return UserProfile(
      lifeStage: lifeStage ?? this.lifeStage,
      dueDate: dueDate ?? this.dueDate,
      babyBirthDate: babyBirthDate ?? this.babyBirthDate,
      allergies: allergies ?? this.allergies,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      cuisines: cuisines ?? this.cuisines,
      healthConditions: healthConditions ?? this.healthConditions,
      babyGender: babyGender ?? this.babyGender,
      gender: gender ?? this.gender,
      language: language ?? this.language,
    );
  }
}
