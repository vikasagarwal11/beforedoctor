import 'package:flutter/material.dart';

class ChildProfileWidget extends StatelessWidget {
  final Map<String, String> childMetadata;
  final void Function(Map<String, String>) onUpdate;

  const ChildProfileWidget({
    required this.childMetadata,
    required this.onUpdate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Basic info display; for full edit dialog see your previous implementation
    return Card(
      child: ListTile(
        leading: const Icon(Icons.child_care),
        title: Text(childMetadata['child_name'] ?? 'No name'),
        subtitle: Text(
          '${childMetadata['child_age'] ?? 'Unknown'} years, ${childMetadata['child_gender'] ?? 'Unknown'}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // Show dialog to edit info and call onUpdate()
          },
        ),
      ),
    );
  }
}
