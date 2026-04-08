import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationStorage {
  static const String _storageKey = 'fintrack_notification_history';

  /// Saves a newly generated notification locally.
  /// If [type] is provided (e.g. 'daily_summary'), any existing notification 
  /// of that same type that hasn't fired yet OR has recently fired is 
  /// typically deleted to avoid duplicates, ensuring only the freshest 
  /// summary is maintained.
  static Future<void> saveNotification(
    String title,
    String body, {
    DateTime? timestamp,
    String? type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];
    
    List<Map<String, dynamic>> notifications = jsonList
        .map((str) => jsonDecode(str) as Map<String, dynamic>)
        .toList();

    // If it's a specific type (e.g., daily_summary), remove the old one so we 
    // don't spam the history if they add 5 transactions in a row.
    if (type != null) {
      notifications.removeWhere((n) => n['type'] == type);
    }

    final newNotification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      'type': type ?? 'general',
    };

    notifications.insert(0, newNotification); // newest first

    final updatedJsonList = notifications.map((n) => jsonEncode(n)).toList();
    await prefs.setStringList(_storageKey, updatedJsonList);
  }

  /// Returns recent notifications, actively pruning anything > 24 hours old.
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];

    if (jsonList.isEmpty) return [];

    final now = DateTime.now();
    bool needsUpdate = false;

    List<Map<String, dynamic>> activeNotifications = [];

    for (var str in jsonList) {
      final data = jsonDecode(str) as Map<String, dynamic>;
      final timestamp = DateTime.parse(data['timestamp'] as String);

      // Check if it's strictly older than 24 hours
      if (now.difference(timestamp).inHours >= 24) {
        needsUpdate = true; // Flag for deletion
      } else {
        activeNotifications.add(data);
      }
    }

    // Sort by timestamp descending (newest / furthest in future first)
    activeNotifications.sort((a, b) {
      final ta = DateTime.parse(a['timestamp'] as String);
      final tb = DateTime.parse(b['timestamp'] as String);
      return tb.compareTo(ta);
    });

    if (needsUpdate) {
      // Save pruned list back to storage
      final updatedJsonList = activeNotifications.map((n) => jsonEncode(n)).toList();
      await prefs.setStringList(_storageKey, updatedJsonList);
    }

    return activeNotifications;
  }
  
  /// Clears all history (just in case)
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
