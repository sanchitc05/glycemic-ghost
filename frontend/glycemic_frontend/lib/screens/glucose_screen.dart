// lib/screens/glucose_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';

import '../models/env_record.dart';
import '../services/api_client.dart';
import '../widgets/glucose_circle.dart';
import '../widgets/glucose_chart.dart';
import '../widgets/range_chip.dart';
import './event_from_screen.dart';
import '../services/health_sync_services.dart';
import '../widgets/fitness_summary_row.dart';
import '../widgets/food_log_sheet.dart';
import '../screens/history_screen.dart';

class GlucoseScreen extends StatefulWidget {
  final String userId;
  final String authToken; // add this so we can call backend

  const GlucoseScreen({
    super.key,
    required this.userId,
    required this.authToken,
  });

  @override
  State<GlucoseScreen> createState() => _GlucoseScreenState();
}

enum GlucoseRangeHours { h3, h6, h12, h24 }

class _GlucoseScreenState extends State<GlucoseScreen> {
  late final ApiClient _apiClient;
  late Future<List<EgvRecord>> _egvFuture;
  GlucoseRangeHours _selectedRange = GlucoseRangeHours.h3;
  Timer? _timer;
  int _selectedTab = 0;

  // simple in‑memory fitness summary (later load from backend)
  int _steps = 0;
  int _calories = 0;
  int _avgHr = 0;
  double? _bmi;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _egvFuture = _apiClient.fetchEgvs(widget.userId);
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      setState(() {
        _egvFuture = _apiClient.fetchEgvs(widget.userId);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _apiClient.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _egvFuture = _apiClient.fetchEgvs(widget.userId);
    });
  }

  Duration _rangeToDuration(GlucoseRangeHours r) {
    switch (r) {
      case GlucoseRangeHours.h3:
        return const Duration(hours: 3);
      case GlucoseRangeHours.h6:
        return const Duration(hours: 6);
      case GlucoseRangeHours.h12:
        return const Duration(hours: 12);
      case GlucoseRangeHours.h24:
        return const Duration(hours: 24);
    }
  }

  // ---------- event sheet ----------

  void _openAddEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _eventRow(
                      'Blood Glucose',
                      'Fingerstick or calibration',
                      _openBloodGlucoseForm,
                    ),
                    _eventRow(
                      'Insulin',
                      'Fast- or long-acting dose',
                      _openInsulinForm,
                    ),
                    _eventRow(
                      'Medication',
                      'Name and dose',
                      _openMedicationForm,
                    ),
                    _eventRow('Meal', 'Carbs you\'ve eaten', _openMealForm),
                    _eventRow(
                      'Activity',
                      'Duration and intensity',
                      _openActivityForm,
                    ),
                    _eventRow(
                      'Fasting glucose',
                      'Wake-up time',
                      _openFastingForm,
                    ),
                    _eventRow('Note', 'Add information', _openNoteForm),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _eventRow(String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  void _openBloodGlucoseForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EventFormScreen(
          title: 'Blood Glucose',
          fields: ['Value (mg/dL)', 'Time', 'Notes'],
        ),
      ),
    );
  }

  void _openInsulinForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EventFormScreen(
          title: 'Insulin',
          fields: ['Type', 'Dose (units)', 'Time', 'Notes'],
        ),
      ),
    );
  }

  void _openMedicationForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EventFormScreen(
          title: 'Medication',
          fields: ['Name', 'Dose', 'Time', 'Notes'],
        ),
      ),
    );
  }

  void _openMealForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EventFormScreen(
          title: 'Meal',
          fields: ['Carbs (g)', 'Food', 'Time', 'Notes'],
        ),
      ),
    );
  }

  void _openActivityForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EventFormScreen(
          title: 'Activity',
          fields: ['Type', 'Duration (min)', 'Intensity', 'Notes'],
        ),
      ),
    );
  }

  void _openFastingForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EventFormScreen(
          title: 'Fasting glucose',
          fields: ['Wake-up time', 'Value (mg/dL)', 'Notes'],
        ),
      ),
    );
  }

  void _openNoteForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const EventFormScreen(title: 'Note', fields: ['Title', 'Details']),
      ),
    );
  }

  // ---------- Health Connect sync ----------

  Future<void> _syncHealth() async {
    await syncHealthData(widget.authToken);
    // TODO: call backend to fetch latest daily aggregates into _steps/_calories/_avgHr/_bmi
    // setState(...) after fetching.
  }

  // ---------- Food logging ----------

  void _openFoodLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: FoodLogSheet(
            token: widget.authToken,
            baseUrl: 'http://localhost:4000',
          ),
        );
      },
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Glycemic Ghost',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.sync),
                          tooltip: 'Sync Health Data',
                          onPressed: _syncHealth,
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<List<EgvRecord>>(
                    future: _egvFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final egvs = snapshot.data ?? [];
                      final now = DateTime.now().toUtc();
                      final rangeDuration = _rangeToDuration(_selectedRange);

                      final filtered = egvs.where((e) {
                        final dt = e.systemTime.toUtc();
                        return now.difference(dt) <= rangeDuration;
                      }).toList();

                      final latest = filtered.isNotEmpty
                          ? filtered.first
                          : (egvs.isNotEmpty ? egvs.first : null);

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GlucoseCircle(value: latest?.value),
                              IconButton(
                                iconSize: 32,
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _openAddEventSheet,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              RangeChip(
                                label: '3 Hours',
                                selected:
                                    _selectedRange == GlucoseRangeHours.h3,
                                onTap: () => setState(() {
                                  _selectedRange = GlucoseRangeHours.h3;
                                }),
                              ),
                              RangeChip(
                                label: '6',
                                selected:
                                    _selectedRange == GlucoseRangeHours.h6,
                                onTap: () => setState(() {
                                  _selectedRange = GlucoseRangeHours.h6;
                                }),
                              ),
                              RangeChip(
                                label: '12',
                                selected:
                                    _selectedRange == GlucoseRangeHours.h12,
                                onTap: () => setState(() {
                                  _selectedRange = GlucoseRangeHours.h12;
                                }),
                              ),
                              RangeChip(
                                label: '24',
                                selected:
                                    _selectedRange == GlucoseRangeHours.h24,
                                onTap: () => setState(() {
                                  _selectedRange = GlucoseRangeHours.h24;
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Expanded(child: GlucoseChart(egvs: filtered)),
                                  FitnessSummaryRow(
                                    steps: _steps,
                                    calories: _calories,
                                    avgHeartRate: _avgHr,
                                    bmi: _bmi,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() => _selectedTab = index);
          switch (index) {
            case 1: // History
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(
                    // ← Fix: add 'context' param
                    userId: widget.userId,
                    authToken: widget.authToken,
                  ),
                ),
              );
              break;
            case 2: // Food
              _openFoodLogSheet();
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Food',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
