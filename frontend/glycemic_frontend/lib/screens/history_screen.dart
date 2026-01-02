import 'package:flutter/material.dart';
import '../services/food_data.dart';
import '../services/food_api.dart';
import '../widgets/food_log_sheet.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;
  final String authToken;
  
  const HistoryScreen({
    super.key, 
    required this.userId, 
    required this.authToken,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7, 
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,  // ✅ FIXED: Pass controller
          tabs: const [
            Tab(text: 'Blood Glucose'),
            Tab(text: 'Insulin'),
            Tab(text: 'Medication'),
            Tab(text: 'Meals'),
            Tab(text: 'Activity'),
            Tab(text: 'Fasting'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,  // ✅ FIXED: Pass controller
        children: [
          _buildEventList('Blood Glucose', Icons.water_drop),
          _buildEventList('Insulin', Icons.local_hospital),
          _buildEventList('Medication', Icons.medication),
          _buildFoodHistory(),
          _buildEventList('Activity', Icons.directions_run),
          _buildEventList('Fasting', Icons.bedtime),
          _buildEventList('Notes', Icons.note),
        ],
      ),
    );
  }

  Widget _buildEventList(String type, IconData icon) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (ctx, i) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(icon, color: Colors.blue),
          title: Text('$type Event', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('2 hours ago • 120 mg/dL'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Open $type details')),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodHistory() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Food Impact', 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 28),
                onPressed: () => _openFoodLogSheet(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 10,
            itemBuilder: (ctx, i) => FoodHistoryCard(
              foodName: i % 3 == 0 ? '2x Chapati' : 
                       i % 3 == 1 ? '1x Apple' : 'Chicken Leg',
              carbs: i % 3 == 0 ? 50.0 : 
                     i % 3 == 1 ? 25.0 : 14.0,
              glucoseImpact: i % 3 == 0 ? 6.5 : 
                            i % 3 == 1 ? 7.8 : 2.5,
              timeAgo: ['1h ago', '2h ago', 'Today', 'Yesterday'][i % 4],
              spikeValue: i % 3 == 0 ? '+25 mg/dL' : 
                         i % 3 == 1 ? '+35 mg/dL' : '+8 mg/dL',
            ),
          ),
        ),
      ],
    );
  }

  void _openFoodLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.9,
        child: FoodLogSheet(
          token: widget.authToken,
          baseUrl: 'http://localhost:4000',
        ),
      ),
    );
  }
}

class FoodHistoryCard extends StatelessWidget {
  final String foodName;
  final double carbs;
  final double glucoseImpact;
  final String timeAgo;
  final String spikeValue;

  const FoodHistoryCard({
    super.key,
    required this.foodName,
    required this.carbs,
    required this.glucoseImpact,
    required this.timeAgo,
    required this.spikeValue,
  });

  @override
  Widget build(BuildContext context) {
    final impactColor = glucoseImpact < 4 ? Colors.green : 
                       glucoseImpact < 7 ? Colors.orange : Colors.red;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: impactColor.withOpacity(0.1),
              child: Icon(Icons.restaurant, color: impactColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(foodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    '${carbs.toStringAsFixed(0)}g carbs • ${glucoseImpact.toStringAsFixed(1)}/10 spike',
                    style: TextStyle(color: impactColor, fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(spikeValue, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: impactColor)),
                const SizedBox(height: 2),
                Text(timeAgo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
