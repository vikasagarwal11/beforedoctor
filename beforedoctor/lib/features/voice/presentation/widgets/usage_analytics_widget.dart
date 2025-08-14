import 'package:flutter/material.dart';

class UsageAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final VoidCallback onClear;

  const UsageAnalyticsWidget({
    required this.analytics,
    required this.onClear,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.analytics),
        title: Text("Total Interactions: ${analytics['total_interactions'] ?? 0}"),
        subtitle: Text("Success Rate: ${analytics['success_rate'] ?? 'N/A'}%"),
        trailing: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: onClear,
        ),
      ),
    );
  }
}
