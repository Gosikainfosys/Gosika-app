import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _key = 'recent_searches';
  static const int _maxItems = 5;

  static Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> current = prefs.getStringList(_key) ?? [];
    current.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    current.insert(0, trimmed);
    if (current.length > _maxItems) {
      current = current.sublist(0, _maxItems);
    }
    await prefs.setStringList(_key, current);
  }

  static Future<void> removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> current = prefs.getStringList(_key) ?? [];
    current.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
    await prefs.setStringList(_key, current);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
