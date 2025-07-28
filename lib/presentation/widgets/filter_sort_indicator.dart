// lib/presentation/widgets/filter_sort_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/sorting_logic.dart';
import '../notifiers/todo_list_notifier.dart';

class FilterSortIndicator extends ConsumerWidget {
  const FilterSortIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = ref.watch(filterStateProvider);
    final sort = ref.watch(sortPreferenceProvider).valueOrNull ?? SortOption.creationDateDesc;
    final search = ref.watch(searchStateProvider);

    if (filter == TodoFilter.all && sort == SortOption.creationDateDesc && search.isEmpty) {
      return const SizedBox.shrink();
    }

    String sortText;
    switch (sort) {
      case SortOption.creationDateDesc: sortText = 'by Newest'; break;
      case SortOption.creationDateAsc: sortText = 'by Oldest'; break;
      case SortOption.dueDate: sortText = 'by Due Date'; break;
      case SortOption.priority: sortText = 'by Priority'; break;
    }

    final List<String> activeFilters = [];
    if (filter != TodoFilter.all) {
      activeFilters.add('Showing ${filter.name} only');
    }
    if (search.isNotEmpty) {
      activeFilters.add('Searching "$search"');
    }
    
    final filterText = activeFilters.join(' ・ ');

    return Material(
      color: theme.colorScheme.primary.withOpacity(0.8),
      child: InkWell(
        onTap: () {
          ref.read(filterStateProvider.notifier).state = TodoFilter.all;
          ref.read(sortPreferenceProvider.notifier).setSortOption(SortOption.creationDateDesc);
          ref.read(searchStateProvider.notifier).state = '';
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Sorted $sortText. $filterText',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.close, size: 16, color: Colors.white),
              const Text('Clear', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}