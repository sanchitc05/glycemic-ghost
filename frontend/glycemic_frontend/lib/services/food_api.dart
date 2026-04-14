import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For debugPrint
import '../services/food_data.dart'; // Your full FoodItem with nutrition

class FoodApi {
  FoodApi(this.baseUrl, this.token);

  final String baseUrl;
  final String token;

  Future<List<FoodItem>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return recommendations();
    }

    try {
      final uri = Uri.parse('$baseUrl/api/food/search?q=${Uri.encodeComponent(trimmed)}');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final foods = (decoded['foods'] as List<dynamic>? ?? const [])
            .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
            .toList();

        if (kDebugMode) {
          debugPrint('Server food search "$trimmed" → ${foods.length} results');
        }
        return foods;
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Server food search failed: $error');
      }
    }

    final matches = foodDatabase
        .where(
          (food) =>
              food.name.toLowerCase().contains(trimmed.toLowerCase()) ||
              food.category.toLowerCase().contains(trimmed.toLowerCase()),
        )
        .take(20)
        .toList();

    if (kDebugMode) {
      debugPrint('Local food search "$trimmed" → ${matches.length} results');
    }
    return matches;
  }

  Future<List<FoodItem>> recommendations() async {
    try {
      final uri = Uri.parse('$baseUrl/api/food/recommendations?limit=20');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final foods = (decoded['foods'] as List<dynamic>? ?? const [])
            .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
            .toList();

        if (foods.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('Server recommendations → ${foods.length} items');
          }
          return foods;
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Server recommendations failed: $error');
      }
    }

    return foodDatabase.take(20).toList();
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
