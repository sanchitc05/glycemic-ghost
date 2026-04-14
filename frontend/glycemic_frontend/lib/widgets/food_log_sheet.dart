import 'package:flutter/material.dart';
import 'dart:async';
import '../services/food_api.dart';
import '../services/food_data.dart'; // Your full FoodItem

class FoodLogSheet extends StatefulWidget {
  final String token;
  final String baseUrl;

  const FoodLogSheet({
    super.key,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<FoodLogSheet> createState() => _FoodLogSheetState();
}

class _FoodLogSheetState extends State<FoodLogSheet> {
  late final FoodApi api;
  final TextEditingController _searchCtrl = TextEditingController();
  List<FoodItem> _results = [];
  bool _loading = false;
  Timer? _searchDebounce;
  String? _selectedPopularFilter;
  List<FoodItem> _defaultRecommendations = [];

  @override
  void initState() {
    super.initState();
    api = FoodApi(widget.baseUrl, widget.token);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (value.trim().isEmpty) {
        _selectedPopularFilter = null;
        _loadRecommendations();
        return;
      }
      _selectedPopularFilter = null;
      _search();
    });
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      await _loadRecommendations();
      return;
    }
    
    setState(() => _loading = true);
    try {
      final foods = await api.search(query);
      setState(() => _results = foods);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _loading = true);
    try {
      final foods = await api.recommendations();
      if (mounted) {
        setState(() {
          _defaultRecommendations = foods;
          _results = foods;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _defaultRecommendations = getRecommendedFoodItems();
          _results = _defaultRecommendations;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load recommendations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _resetSearch() {
    _searchDebounce?.cancel();
    _selectedPopularFilter = null;
    _searchCtrl.clear();
    _loadRecommendations();
  }

  void _applyPopularFilter(String filterLabel) {
    final normalized = filterLabel.toLowerCase();
    List<FoodItem> filtered;

    if (normalized == 'north indian') {
      filtered = foodDatabase.where((food) {
        final text = '${food.name} ${food.category}'.toLowerCase();
        return text.contains('chapati') ||
            text.contains('roti') ||
            text.contains('paratha') ||
            text.contains('rajma') ||
            text.contains('chole') ||
            text.contains('paneer') ||
            text.contains('dal');
      }).toList();
    } else if (normalized == 'south indian') {
      filtered = foodDatabase.where((food) {
        final text = '${food.name} ${food.category}'.toLowerCase();
        return text.contains('idli') ||
            text.contains('dosa') ||
            text.contains('uttapam') ||
            text.contains('sambar') ||
            text.contains('pongal') ||
            text.contains('curd rice');
      }).toList();
    } else if (normalized == 'street food') {
      filtered = foodDatabase.where((food) {
        final text = '${food.name} ${food.category}'.toLowerCase();
        return text.contains('vada pav') ||
            text.contains('misal') ||
            text.contains('bhel') ||
            text.contains('dhokla') ||
            text.contains('khakra');
      }).toList();
    } else if (normalized == 'protein rich') {
      filtered = foodDatabase.where((food) {
        final text = '${food.name} ${food.category}'.toLowerCase();
        return text.contains('paneer') ||
            text.contains('chicken') ||
            text.contains('dal') ||
            text.contains('sprouts') ||
            text.contains('chole');
      }).toList();
    } else if (normalized == 'low spike') {
      filtered = foodDatabase
          .where((food) => food.glucoseImpactScore <= 4.5)
          .toList();
    } else {
      filtered = _defaultRecommendations;
    }

    setState(() {
      _selectedPopularFilter = filterLabel;
      _results = filtered;
    });
  }

  Future<void> _logFood(FoodItem item) async {
    double quantity = 1.0;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _QuantityDialog(
        item: item,
        initialQuantity: 1.0,
        onLog: (qty) async {
          try {
            final loggedItem = item.scale(qty);
            await api.logFood(item.id, qty, loggedItem);
            Navigator.pop(ctx);
            Navigator.pop(context); // Close sheet
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logged ${qty.toStringAsFixed(1)}x ${item.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to log: $e')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add food',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search food (e.g. chapati, apple)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _resetSearch,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _search(),
                textInputAction: TextInputAction.search,
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (_searchCtrl.text.trim().isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'Popular in Indian kitchens',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _RecommendationChip(
                            label: 'North Indian',
                            selected: _selectedPopularFilter == 'North Indian',
                            onSelected: () => _applyPopularFilter('North Indian'),
                          ),
                          _RecommendationChip(
                            label: 'South Indian',
                            selected: _selectedPopularFilter == 'South Indian',
                            onSelected: () => _applyPopularFilter('South Indian'),
                          ),
                          _RecommendationChip(
                            label: 'Street Food',
                            selected: _selectedPopularFilter == 'Street Food',
                            onSelected: () => _applyPopularFilter('Street Food'),
                          ),
                          _RecommendationChip(
                            label: 'Protein rich',
                            selected: _selectedPopularFilter == 'Protein rich',
                            onSelected: () => _applyPopularFilter('Protein rich'),
                          ),
                          _RecommendationChip(
                            label: 'Low spike',
                            selected: _selectedPopularFilter == 'Low spike',
                            onSelected: () => _applyPopularFilter('Low spike'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                      child: Center(
                        child: Text(
                          'Search for foods above\ne.g. chapati, idli, poha',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._results.map(
                      (item) {
                        final impactColor = _getImpactColor(item.glucoseImpactScore);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: impactColor.withOpacity(0.2),
                              child: Icon(Icons.restaurant_menu, color: impactColor),
                            ),
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item.servingSize} • ${item.calories} kcal'),
                                Text(
                                  '${item.carbsG.toStringAsFixed(0)}g carbs • '
                                  '${item.proteinG.toStringAsFixed(0)}g protein • '
                                  '${item.glucoseImpactScore.toStringAsFixed(1)}/10 spike',
                                  style: TextStyle(
                                    color: impactColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () => _logFood(item),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getImpactColor(double score) {
    if (score < 4) return Colors.green;
    if (score < 7) return Colors.orange;
    return Colors.red;
  }
}

// Inline Quantity Dialog (no separate class needed)
class _QuantityDialog extends StatefulWidget {
  final FoodItem item;
  final double initialQuantity;
  final void Function(double) onLog;

  const _QuantityDialog({
    required this.item,
    required this.initialQuantity,
    required this.onLog,
  });

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late double quantity;
  late final TextEditingController _quantityCtrl;

  List<PortionPreset> get _presets => foodPortionPresets[widget.item.id] ?? defaultPortionPresets;

  @override
  void initState() {
    super.initState();
    quantity = widget.initialQuantity;
    _quantityCtrl = TextEditingController(text: quantity.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    super.dispose();
  }

  void _setQuantity(double value) {
    setState(() {
      quantity = value;
      _quantityCtrl.text = quantity.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaled = widget.item.scale(quantity);
    final impactColor = quantity < 4 ? Colors.green : 
                       quantity < 7 ? Colors.orange : Colors.red;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.glucoseImpactDesc,
              style: TextStyle(
                color: impactColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(preset.label),
                      selected: (quantity - preset.quantity).abs() < 0.001,
                      onSelected: (_) => _setQuantity(preset.quantity),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity / servings',
                hintText: widget.item.servingSize,
                border: const OutlineInputBorder(),
                suffixText: 'servings',
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value);
                if (parsed != null && parsed > 0) {
                  quantity = parsed;
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${scaled.carbsG.toStringAsFixed(0)}g carbs'),
                  Text('${scaled.sugarG.toStringAsFixed(1)}g sugar'),
                  Text('${scaled.proteinG.toStringAsFixed(0)}g protein'),
                  const SizedBox(height: 6),
                  Text(
                    '${scaled.servingWeightG.toStringAsFixed(0)}g total portion',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                IconButton(
                  onPressed: quantity > 0.25 
                      ? () => _setQuantity((quantity - 0.25).clamp(0.25, 99))
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${quantity.toStringAsFixed(2)}x ${widget.item.servingSize}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _setQuantity((quantity + 0.25).clamp(0.25, 99)),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => widget.onLog(quantity),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: impactColor,
                  ),
                  child: const Text('Log Food'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _RecommendationChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.green.shade100,
      side: BorderSide(color: selected ? Colors.green : Colors.grey.shade300),
    );
  }
}
