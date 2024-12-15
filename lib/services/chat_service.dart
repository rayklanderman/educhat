import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/message_model.dart';

final chatServiceProvider = Provider((ref) => ChatService());

class ChatService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>> _subscriptions = {};

  // Create a new chat
  Future<String> createChat({
    required String type,
    required List<String> participantIds,
    String? name,
  }) async {
    // Start a transaction
    final response = await _supabase.rpc('create_chat', params: {
      'chat_type': type,
      'chat_name': name,
      'participant_ids': participantIds,
    });

    return response['chat_id'] as String;
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String content,
    required MessageType type,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    
    await _supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': userId,
      'content': {
        'text': content,
        'type': type.name,
        'metadata': metadata,
      },
    });
  }

  // Get chat messages
  Future<List<MessageModel>> getChatMessages(String chatId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at');

    return response.map((json) => MessageModel.fromJson(json)).toList();
  }

  // Subscribe to chat messages
  StreamSubscription<List<MessageModel>> subscribeToChatMessages(
    String chatId,
    void Function(List<MessageModel>) onMessagesReceived,
  ) {
    // Cancel existing subscription if any
    _subscriptions[chatId]?.cancel();

    final subscription = _supabase
        .from('messages')
        .stream(primaryKey: ['message_id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map((events) => events.map((event) => MessageModel.fromJson(event)).toList())
        .listen(onMessagesReceived);

    _subscriptions[chatId] = subscription as StreamSubscription<List<Map<String, dynamic>>>;
    return subscription;
  }

  // Get user's chats
  Future<List<Map<String, dynamic>>> getUserChats() async {
    final userId = _supabase.auth.currentUser!.id;
    
    return await _supabase
        .from('chat_participants')
        .select('''
          chat:chats (
            chat_id,
            type,
            name,
            created_at,
            participants:chat_participants (
              user:users (
                user_id,
                name,
                avatar_url
              )
            )
          )
        ''')
        .eq('user_id', userId)
        .order('joined_at', ascending: false);
  }

  // Upload file to chat
  Future<String> uploadFile(String chatId, List<int> bytes, String fileName) async {
    final userId = _supabase.auth.currentUser!.id;
    final extension = fileName.split('.').last;
    final path = '$chatId/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';
    
    await _supabase.storage.from('chat-files').uploadBinary(path, bytes);
    final url = _supabase.storage.from('chat-files').getPublicUrl(path);
    
    return url;
  }

  // Clean up subscriptions
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
