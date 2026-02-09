import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReelTypeChoiceScreen extends StatelessWidget {
  final String? categoryId;

  const ReelTypeChoiceScreen({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Format wählen'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Was möchtest du heute sehen?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _buildChoiceCard(
              context,
              title: 'Kurze Lernvideos',
              subtitle: 'Interaktive Reels aus unserer Datenbank',
              icon: Icons.bolt,
              color: Colors.blue.shade700,
              onTap: () => context.push('/reels/feed?categoryId=$categoryId&onlyYoutube=false'),
            ),
            const SizedBox(height: 24),
            _buildChoiceCard(
              context,
              title: 'YouTube Tutorials',
              subtitle: 'Ausführliche Erklärungen von YouTube',
              icon: Icons.play_circle_filled,
              color: Colors.red.shade700,
              onTap: () => context.push('/reels/feed?categoryId=$categoryId&onlyYoutube=true'),
            ),
            const SizedBox(height: 48),
            TextButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Zurück zur Themenübersicht'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
          ],
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
