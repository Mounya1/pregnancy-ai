class MealItem {
  final String name;
  final String description;
  final String whyGood;

  MealItem({required this.name, required this.description, required this.whyGood});

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
        name: json['name'] as String,
        description: json['description'] as String,
        whyGood: json['why_good'] as String,
      );

  Map<String, dynamic> toJson() => {'name': name, 'description': description, 'why_good': whyGood};
}

class DayPlan {
  final String dayLabel;
  final MealItem breakfast;
  final MealItem lunch;
  final MealItem dinner;
  final MealItem snack;

  DayPlan({
    required this.dayLabel,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        dayLabel: json['day_label'] as String,
        breakfast: MealItem.fromJson(json['breakfast']),
        lunch: MealItem.fromJson(json['lunch']),
        dinner: MealItem.fromJson(json['dinner']),
        snack: MealItem.fromJson(json['snack']),
      );

  Map<String, dynamic> toJson() => {
        'day_label': dayLabel,
        'breakfast': breakfast.toJson(),
        'lunch': lunch.toJson(),
        'dinner': dinner.toJson(),
        'snack': snack.toJson(),
      };
}

/// One line of the shopping list for a whole meal plan.
class GroceryItem {
  final String name;
  final String quantity;

  /// Store aisle, from a fixed set chosen by the backend - see [kGrocerySections].
  final String section;

  /// Ticked off while shopping. Saved with the plan so it survives a restart.
  bool checked;

  GroceryItem({
    required this.name,
    this.quantity = '',
    this.section = 'Other',
    this.checked = false,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
        name: json['name'] as String? ?? '',
        quantity: json['quantity'] as String? ?? '',
        section: json['section'] as String? ?? 'Other',
        checked: json['checked'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'section': section,
        'checked': checked,
      };
}

/// Aisle order, walking a typical shop. Mirrors GROCERY_SECTIONS in
/// backend/app/routers/meal_plan.py.
const kGrocerySections = [
  'Produce',
  'Dairy & eggs',
  'Meat & fish',
  'Grains & bread',
  'Pantry',
  'Frozen',
  'Other',
];

class MealPlan {
  final String summary;
  final List<DayPlan> days;
  final String disclaimer;
  final DateTime generatedAt;

  /// Empty for plans saved before grocery lists existed.
  final List<GroceryItem> groceryList;

  MealPlan({
    required this.summary,
    required this.days,
    this.disclaimer = 'This is not medical advice. Consult your doctor or a registered dietitian.',
    DateTime? generatedAt,
    this.groceryList = const [],
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
        summary: json['summary'] as String,
        days: (json['days'] as List).map((d) => DayPlan.fromJson(d)).toList(),
        disclaimer: json['disclaimer'] as String? ??
            'This is not medical advice. Consult your doctor or a registered dietitian.',
        generatedAt: json['generated_at'] != null ? DateTime.tryParse(json['generated_at']) : null,
        groceryList: (json['grocery_list'] as List? ?? const [])
            .map((g) => GroceryItem.fromJson(g as Map<String, dynamic>))
            .where((g) => g.name.isNotEmpty)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'days': days.map((d) => d.toJson()).toList(),
        'disclaimer': disclaimer,
        'generated_at': generatedAt.toIso8601String(),
        'grocery_list': groceryList.map((g) => g.toJson()).toList(),
      };

  /// The list grouped by aisle, in shop order, for display and for copying.
  List<(String, List<GroceryItem>)> get groceriesBySection => [
        for (final section in kGrocerySections)
          if (groceryList.any((g) => _sectionOf(g) == section))
            (section, groceryList.where((g) => _sectionOf(g) == section).toList()),
      ];

  static String _sectionOf(GroceryItem g) =>
      kGrocerySections.contains(g.section) ? g.section : 'Other';

  /// Plain text for pasting into a notes app or a message.
  String groceryListAsText() {
    final buffer = StringBuffer('Grocery list\n');
    for (final (section, items) in groceriesBySection) {
      buffer.writeln('\n$section');
      for (final item in items) {
        final qty = item.quantity.isEmpty ? '' : ' - ${item.quantity}';
        buffer.writeln('${item.checked ? '[x]' : '[ ]'} ${item.name}$qty');
      }
    }
    return buffer.toString().trimRight();
  }
}
