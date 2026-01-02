import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    api = FoodApi(widget.baseUrl, widget.token);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    
    setState(() => _loading = true);
    try {
      final foods = await api.search(_searchCtrl.text.trim());
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
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _results = []);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _search(),
                textInputAction: TextInputAction.search,
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text(
                        'Search for foods above\ne.g. chapati, apple, chicken',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (ctx, i) {
                        final item = _results[i];
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

  @override
  void initState() {
    super.initState();
    quantity = widget.initialQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final scaled = widget.item.scale(quantity);
    final impactColor = quantity < 4 ? Colors.green : 
                       quantity < 7 ? Colors.orange : Colors.red;

    return Padding(
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('${scaled.carbsG.toStringAsFixed(0)}g carbs'),
                Text('${scaled.sugarG.toStringAsFixed(1)}g sugar'),
                Text('${scaled.proteinG.toStringAsFixed(0)}g protein'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              IconButton(
                onPressed: quantity > 0.25 
                    ? () => setState(() => quantity -= 0.25)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${quantity.toStringAsFixed(1)}x ${widget.item.servingSize}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => quantity += 0.25),
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
    );
  }
}
