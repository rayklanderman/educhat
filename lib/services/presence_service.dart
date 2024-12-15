import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

final presenceServiceProvider = Provider((ref) => PresenceService());

class PresenceService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  Timer? _presenceTimer;
  Timer? _typingTimer;
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>> _subscriptions = {};

  // Start updating presence
  void startPresenceUpdates() {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updatePresence();
    });
    _updatePresence(); // Update immediately
  }

  // Stop updating presence
  void stopPresenceUpdates() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    _updateOffline();
  }

  // Update user's presence
  Future<void> _updatePresence() async {
    try {
      await _supabase.from('users').update({
        'last_seen': DateTime.now().toIso8601String(),
        'is_online': true,
      }).eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      // Handle error silently
      print('Error updating presence: $e');
    }
  }

  // Update user's offline status
  Future<void> _updateOffline() async {
    try {
      await _supabase.from('users').update({
        'is_online': false,
        'is_typing': '{}',
      }).eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      // Handle error silently
      print('Error updating offline status: $e');
    }
  }

  // Subscribe to user presence
  StreamSubscription<List<Map<String, dynamic>>> subscribeToPresence(
    String userId,
    void Function(bool isOnline, DateTime lastSeen) onPresenceChange,
  ) {
    // Cancel existing subscription if any
    _subscriptions[userId]?.cancel();

    final subscription = _supabase
        .from('users')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((events) {
          if (events.isEmpty) return;
          final user = events.first;
          final isOnline = user['is_online'] as bool? ?? false;
          final lastSeen = DateTime.parse(user['last_seen'] as String);
          onPresenceChange(isOnline, lastSeen);
        })
        .listen((_) {});

    _subscriptions[userId] = subscription;
    return subscription;
  }

  // Update typing status
  Future<void> updateTypingStatus(String chatId, {required bool isTyping}) async {
    _typingTimer?.cancel();

    try {
      await _supabase.rpc(
        'update_typing_status',
        params: {
          'chat_id': chatId,
          'is_typing': isTyping,
        },
      );

      if (isTyping) {
        // Auto-reset typing status after 5 seconds of inactivity
        _typingTimer = Timer(const Duration(seconds: 5), () {
          updateTypingStatus(chatId, isTyping: false);
        });
      }
    } catch (e) {
      // Handle error silently
      print('Error updating typing status: $e');
    }
  }

  // Subscribe to typing status
  StreamSubscription<List<Map<String, dynamic>>> subscribeToTypingStatus(
    String chatId,
    void Function(String userId, bool isTyping) onTypingChange,
  ) {
    final subscription = _supabase
        .from('users')
        .stream(primaryKey: ['user_id'])
        .not('user_id', 'eq', _supabase.auth.currentUser!.id)
        .map((events) {
          for (final user in events) {
            final typingData = user['is_typing'] as Map<String, dynamic>?;
            if (typingData == null) continue;

            final typingTimestamp = typingData[chatId] as num?;
            if (typingTimestamp == null) {
              onTypingChange(user['user_id'] as String, false);
              continue;
            }

            // Check if typing timestamp is within last 6 seconds
            final typingTime = DateTime.fromMillisecondsSinceEpoch(
              (typingTimestamp * 1000).toInt(),
            );
            final isTyping = DateTime.now().difference(typingTime).inSeconds < 6;
            onTypingChange(user['user_id'] as String, isTyping);
          }
        })
        .listen((_) {});

    return subscription;
  }

  // Clean up
  void dispose() {
    _presenceTimer?.cancel();
    _typingTimer?.cancel();
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
