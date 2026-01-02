import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For debugPrint
import '../services/food_data.dart'; // Your full FoodItem with nutrition

class FoodApi {
  FoodApi(this.baseUrl, this.token);

  final String baseUrl;
  final String token;

  Future<List<FoodItem>> search(String query) async {
    // Use your local foodDatabase first (fast, offline)
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network
    final matches = foodDatabase
        .where(
          (food) =>
              food.name.toLowerCase().contains(query.toLowerCase()) ||
              food.category.toLowerCase().contains(query.toLowerCase()),
        )
        .take(20)
        .toList();

    if (kDebugMode) {
      debugPrint('Food search "$query" → ${matches.length} results');
    }
    return matches;
  }

  Future<void> logFood(
    int foodId,
    double quantity,
    FoodItem fullItem,
  ) async {
    // here we are calling the url
    final uri = Uri.parse('$baseUrl/api/food/log');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'foodId': foodId,
        'quantity': quantity,
        'nutrition': {
          'name': fullItem.name,
          'calories': (fullItem.calories * quantity).round(), // ✅ SCALED
          'carbsG': fullItem.carbsG * quantity, // ✅ SCALED (FIX!)
          'sugarG': fullItem.sugarG * quantity, // ✅ SCALED
          'proteinG': fullItem.proteinG * quantity, // ✅ SCALED
          'fatG': fullItem.fatG * quantity, // ✅ SCALED
          'fiberG': fullItem.fiberG * quantity, // ✅ SCALED
          'glucoseImpactScore': fullItem.glucoseImpactScore,
          'vitamins': fullItem.vitamins.map(
            (k, v) => MapEntry(k, v * quantity),
          ),
          'minerals': fullItem.minerals.map(
            (k, v) => MapEntry(k, v * quantity),
          ),
        },
        'loggedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Log food failed: ${res.statusCode} ${res.body}');
    }
  }

  // Backward compatibility for old code
  Future<void> logFoodOld(int foodId, double quantity) async {
    final food = foodDatabase.firstWhere((f) => f.id == foodId);
    await logFood(foodId, quantity, food);
  }
}
