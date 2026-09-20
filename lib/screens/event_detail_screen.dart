import 'package:flutter/material.dart';
import 'register_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final String title;
  final String description;

  const EventDetailScreen({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen(eventTitle: title)),
                );
              },
              child: const Text("Daftar Sekarang"),
            ),
          ],
        ),
      ),
    );
  }
}
