// lib/screens/event_form_screen.dart
import 'package:flutter/material.dart';

class EventFormScreen extends StatelessWidget {
  final String title;
  final List<String> fields;

  const EventFormScreen({
    super.key,
    required this.title,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    final controllers = {
      for (final f in fields) f: TextEditingController(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final field in fields) ...[
              TextField(
                controller: controllers[field],
                decoration: InputDecoration(
                  labelText: field,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: send to backend
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
