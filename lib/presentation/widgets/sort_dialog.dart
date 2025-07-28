// lib/presentation/widgets/sort_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/sorting_logic.dart';

class SortDialog extends ConsumerWidget {
  const SortDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSortOption = ref.watch(sortPreferenceProvider).valueOrNull ?? SortOption.creationDateDesc;
    final theme = Theme.of(context); 

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: const Text('Sort by'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...SortOption.values.map((option) {
            return _SortOptionRadio(
              title: _getSortOptionTitle(option),
              value: option,
              groupValue: currentSortOption,
              onChanged: (val) {
                if (val != null) {
                  ref.read(sortPreferenceProvider.notifier).setSortOption(val);
                }
                Navigator.of(context).pop();
              },
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _getSortOptionTitle(SortOption option) {
    switch (option) {
      case SortOption.creationDateDesc: return 'Newest First';
      case SortOption.creationDateAsc: return 'Oldest First';
      case SortOption.dueDate: return 'By Due Date';
      case SortOption.priority: return 'By Priority';
    }
  }
}

class _SortOptionRadio extends StatelessWidget {
  final String title;
  final SortOption value;
  final SortOption groupValue;
  final ValueChanged<SortOption?> onChanged;

  const _SortOptionRadio({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<SortOption>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.secondary,
    );
  }
}