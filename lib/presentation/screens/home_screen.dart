// lib/presentation/screens/home_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mark_it_down_v2/logic/auth_service.dart';
import 'package:mark_it_down_v2/presentation/theme/app_theme.dart';
import 'package:mark_it_down_v2/routing/app_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:confetti/confetti.dart';

import '../../data/models/todo.dart';
import '../../logic/sorting_logic.dart';
import '../notifiers/theme_notifier.dart' hide AppTheme;
import '../notifiers/todo_list_notifier.dart';
import '../widgets/completed_section_header.dart';
import '../widgets/todo_item.dart';
import '../widgets/todo_item_skeleton.dart';
import '../utils/group_by_date.dart';
import '../widgets/sort_dialog.dart';
import '../widgets/filter_sort_indicator.dart';
import '../widgets/celebration_header.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(searchStateProvider);
    final themeMode = ref.watch(appThemeProvider).valueOrNull ?? ThemeMode.system;
    final isDarkMode = (themeMode == ThemeMode.dark || 
                       (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark));
    final isSearchVisible = ref.watch(searchVisibleProvider);
    final searchController = useTextEditingController();
    final isCompletedExpanded = useState(true);
    final confettiController = useMemoized(() => ConfettiController(duration: const Duration(seconds: 1)), []);
    useEffect(() => confettiController.dispose, []);

    ref.listen<AsyncValue<List<Todo>>>(todoListProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        return;
      }
      if (previous is! AsyncData || next is! AsyncData) return;
      final prevTodos = previous?.value;
      final nextTodos = next.value;
      if (prevTodos == null || nextTodos == null) return;
      final prevActiveCount = prevTodos.where((t) => !t.completed).length;
      final nextActiveCount = nextTodos.where((t) => !t.completed).length;
      if (prevActiveCount > 0 && nextActiveCount == 0) confettiController.play();
      if (prevTodos.isNotEmpty && nextTodos.isEmpty) confettiController.play();
    });

    TextStyle getHeaderTextStyle() {
      return Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true, // Allow body to go behind app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        title: isSearchVisible
            ? TextField(
                controller: searchController,
                autofocus: true,
                onChanged: (value) => ref.read(searchStateProvider.notifier).state = value,
                decoration: InputDecoration(
                  hintText: 'Search todos...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      searchController.clear();
                      ref.read(searchStateProvider.notifier).state = '';
                      ref.read(searchVisibleProvider.notifier).state = false;
                    },
                  ),
                ),
                style: const TextStyle(fontSize: 18),
              )
            : const Text('Mark It Down'),
        actions: [
          if (!isSearchVisible)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => ref.read(searchVisibleProvider.notifier).state = true,
            ),
          if (!isSearchVisible)
            PopupMenuButton<TodoFilter>(
              icon: const Icon(Icons.filter_list),
              initialValue: ref.watch(filterStateProvider),
              onSelected: (filter) => ref.read(filterStateProvider.notifier).state = filter,
              itemBuilder: (_) => [
                const PopupMenuItem(value: TodoFilter.all, child: Text('All')),
                const PopupMenuItem(value: TodoFilter.active, child: Text('Active')),
                const PopupMenuItem(value: TodoFilter.completed, child: Text('Completed')),
              ],
            ),
          if (!isSearchVisible)
            PopupMenuButton<VoidCallback>(
              icon: const Icon(Icons.more_vert),
              onSelected: (callback) => callback(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: () => showDialog(context: context, builder: (_) => const SortDialog()),
                  child: const ListTile(leading: Icon(Icons.sort), title: Text('Sort By')),
                ),
                PopupMenuItem(
                  value: () => context.push(AppRoutes.stats),
                  child: const ListTile(leading: Icon(Icons.bar_chart), title: Text('Statistics')),
                ),
                PopupMenuItem(
                  value: () => ref.read(appThemeProvider.notifier).toggleTheme(),
                  child: ListTile(
                    leading: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                    title: const Text('Toggle Theme'),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: () => ref.read(authServiceProvider).signOut(),
                  child: const ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Sign Out'),
                  ),
                ),
              ],
            ),
        ],
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppTheme.darkGradient : AppTheme.lightGradient,
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SafeArea(
              child: Column(
                children: [
                  const FilterSortIndicator(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref.read(todoListProvider.notifier).refresh(),
                      child: Builder(
                        builder: (context) {
                          final todoListAsync = ref.watch(todoListProvider);
                          if (todoListAsync is AsyncLoading && !todoListAsync.hasValue) {
                            return Shimmer.fromColors(
                              baseColor: isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
                              highlightColor: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(top: 8),
                                itemCount: 5,
                                itemBuilder: (_, __) => const TodoItemSkeleton(),
                              ),
                            );
                          }
                      
                          if (todoListAsync.hasError && !todoListAsync.hasValue) {
                            return Center(child: Text('Something went wrong: ${todoListAsync.error}'));
                          }
                      
                          final lists = ref.watch(filteredTodosProvider);
                          final activeTodos = lists.active;
                          final completedTodos = lists.completed;
                          final totalTodos = todoListAsync.valueOrNull ?? [];
                          
                          if (totalTodos.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset('assets/images/undraw_add_notes.svg', width: MediaQuery.of(context).size.width * 0.6),
                                  const SizedBox(height: 24),
                                  Text('Add your first todo!', style: Theme.of(context).textTheme.titleLarge),
                                ],
                              ),
                            );
                          }
                      
                          final groupedActiveTodos = groupByDate(activeTodos);
                          final dateKeys = groupedActiveTodos.keys.toList();
                      
                          return CustomScrollView(
                            key: ValueKey('${isDarkMode}_${ref.watch(sortPreferenceProvider)}'),
                            slivers: [
                              if (activeTodos.isEmpty && completedTodos.isEmpty && totalTodos.isNotEmpty)
                                SliverFillRemaining(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Text('No todos found for your search/filter.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                                    ),
                                  ),
                                ),
                      
                              if (activeTodos.isEmpty && completedTodos.isNotEmpty && search.isEmpty)
                                const SliverToBoxAdapter(child: CelebrationHeader()),
                      
                              for (final dateKey in dateKeys) ...[
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                                    child: Text(dateKey, style: getHeaderTextStyle()),
                                  ),
                                ),
                                SliverList.list(
                                  children: groupedActiveTodos[dateKey]!
                                      .map((todo) => TodoItem(key: ValueKey(todo.id), todo: todo))
                                      .toList()
                                      .animate(interval: 60.ms)
                                      .fade(duration: 400.ms)
                                      .slideX(begin: -0.2, curve: Curves.easeOutCubic),
                                ),
                              ],
                      
                              if (completedTodos.isNotEmpty) ...[
                                SliverToBoxAdapter(
                                  child: CompletedSectionHeader(
                                    completedCount: completedTodos.length,
                                    isExpanded: isCompletedExpanded.value,
                                    onToggle: () => isCompletedExpanded.value = !isCompletedExpanded.value,
                                    confettiController: confettiController,
                                  ),
                                ),
                                if (isCompletedExpanded.value)
                                  SliverList.list(
                                    children: completedTodos
                                        .map((todo) => Opacity(opacity: 0.7, child: TodoItem(key: ValueKey(todo.id), todo: todo)))
                                        .toList().animate().fade(duration: 400.ms),
                                  ),
                                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.add),
        child: const Icon(Icons.add),
      ),
    );
  }
}