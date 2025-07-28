// lib/logic/sorting_logic.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'sorting_logic.g.dart';

// Enum for our sorting options
enum SortOption {
  creationDateDesc,
  creationDateAsc,
  dueDate,
  priority,
}

// A Notifier to manage and persist the user's sort preference.
@riverpod
class SortPreference extends _$SortPreference {
  late SharedPreferences _prefs;
  static const _key = 'sort_preference';

  @override
  Future<SortOption> build() async {
    _prefs = await SharedPreferences.getInstance();
    final savedIndex = _prefs.getInt(_key) ?? 0;
    return SortOption.values[savedIndex];
  }

  Future<void> setSortOption(SortOption option) async {
    await _prefs.setInt(_key, option.index);
    state = AsyncData(option);
  }
}