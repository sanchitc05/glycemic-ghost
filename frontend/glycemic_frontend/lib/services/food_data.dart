class FoodItem {
  final int id;
  final String name;
  final String category;
  final String servingSize;
  final double servingWeightG;
  final int calories;
  final double carbsG;
  final double sugarG;
  final double proteinG;
  final double fatG;
  final double fiberG;
  final Map<String, double> vitamins; // vitamin A, C, etc.
  final Map<String, double> minerals; // calcium, iron, etc.
  final double glucoseImpactScore; // 0-10 (how much it spikes)
  final String glucoseImpactDesc;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.servingSize,
    required this.servingWeightG,
    required this.calories,
    required this.carbsG,
    required this.sugarG,
    required this.proteinG,
    required this.fatG,
    required this.fiberG,
    required this.vitamins,
    required this.minerals,
    required this.glucoseImpactScore,
    required this.glucoseImpactDesc,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: json['id'],
    name: json['name'],
    category: json['category'],
    servingSize: json['servingSize'],
    servingWeightG: (json['servingWeightG'] as num).toDouble(),
    calories: json['calories'],
    carbsG: (json['carbsG'] as num).toDouble(),
    sugarG: (json['sugarG'] as num).toDouble(),
    proteinG: (json['proteinG'] as num).toDouble(),
    fatG: (json['fatG'] as num).toDouble(),
    fiberG: (json['fiberG'] as num).toDouble(),
    vitamins: Map<String, double>.from(json['vitamins'] ?? {}),
    minerals: Map<String, double>.from(json['minerals'] ?? {}),
    glucoseImpactScore: (json['glucoseImpactScore'] as num).toDouble(),
    glucoseImpactDesc: json['glucoseImpactDesc'],
  );

  FoodItem scale(double quantity) => FoodItem(
    id: id,
    name: name,
    category: category,
    servingSize: servingSize,
    servingWeightG: servingWeightG * quantity,
    calories: (calories * quantity).round(),
    carbsG: carbsG * quantity,
    sugarG: sugarG * quantity,
    proteinG: proteinG * quantity,
    fatG: fatG * quantity,
    fiberG: fiberG * quantity,
    vitamins: vitamins.map((k, v) => MapEntry(k, v * quantity)),
    minerals: minerals.map((k, v) => MapEntry(k, v * quantity)),
    glucoseImpactScore: glucoseImpactScore,
    glucoseImpactDesc: glucoseImpactDesc,
  );
}

// 50+ Indian foods with realistic glucose impact
final List<FoodItem> foodDatabase = [
  FoodItem(
    id: 1,
    name: 'Chapati (1 medium)',
    category: 'Grains',
    servingSize: '1 piece (40g)',
    servingWeightG: 40,
    calories: 120,
    carbsG: 25,
    sugarG: 0.5,
    proteinG: 3.5,
    fatG: 0.5,
    fiberG: 3,
    vitamins: {'B1': 0.1},
    minerals: {'Iron': 1.2},
    glucoseImpactScore: 6.5,
    glucoseImpactDesc: 'Moderate spike',
  ),
  FoodItem(
    id: 2,
    name: 'Apple (medium)',
    category: 'Fruits',
    servingSize: '1 apple (180g)',
    servingWeightG: 180,
    calories: 95,
    carbsG: 25,
    sugarG: 19,
    proteinG: 0.5,
    fatG: 0.3,
    fiberG: 4.4,
    vitamins: {'C': 14},
    minerals: {'Potassium': 195},
    glucoseImpactScore: 7.8, // High due to fructose
    glucoseImpactDesc: 'High spike (fructose)',
  ),
  FoodItem(
    id: 3,
    name: 'Chicken Leg (KFC style)',
    category: 'Protein',
    servingSize: '1 leg (100g)',
    servingWeightG: 100,
    calories: 250,
    carbsG: 14,
    sugarG: 0,
    proteinG: 25,
    fatG: 15,
    fiberG: 0,
    vitamins: {'B3': 10},
    minerals: {'Zinc': 2},
    glucoseImpactScore: 2.5, // Low carb
    glucoseImpactDesc: 'Minimal impact',
  ),
  // Add 47 more foods...

  // Add to your foodDatabase:
FoodItem(id: 4, name: 'Rice (cooked, 1 cup)', category: 'Grains', servingSize: '200g', servingWeightG: 200, calories: 240, carbsG: 53, sugarG: 0, proteinG: 4, fatG: 0.4, fiberG: 0.6, vitamins: {}, minerals: {}, glucoseImpactScore: 8.5, glucoseImpactDesc: 'High spike'),
FoodItem(id: 5, name: 'Dal (1 bowl)', category: 'Legumes', servingSize: '150g', servingWeightG: 150, calories: 180, carbsG: 28, sugarG: 2, proteinG: 12, fatG: 1, fiberG: 8, vitamins: {'B9': 180}, minerals: {'Iron': 3.5}, glucoseImpactScore: 4.2, glucoseImpactDesc: 'Low-moderate'),
// Add more: Paneer, Roti, Banana, Curd, etc.

];
