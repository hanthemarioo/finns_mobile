import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}