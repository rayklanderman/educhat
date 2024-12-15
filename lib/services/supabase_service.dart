import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  // Authentication Methods
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        final userData = await _client
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();
        
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> register(String name, String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user != null) {
        final user = UserModel(
          id: response.user!.id,
          name: name,
          email: email,
          role: 'student',
          createdAt: DateTime.now(),
        );

        await _client.from('users').insert(user.toJson());
        return user;
      }
      throw Exception('Registration failed');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Chat Methods
  Future<List<ChatModel>> getChats(String userId) async {
    try {
      final response = await _client
          .from('chats')
          .select('*, participants!inner(*)')
          .eq('participants.user_id', userId)
          .order('last_message_time', ascending: false);

      return (response as List).map((chat) => ChatModel.fromJson(chat)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<ChatModel> createChat({
    required String name,
    required ChatType type,
    required List<String> participantIds,
  }) async {
    try {
      final chatData = {
        'name': name,
        'type': type.toString().split('.').last,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _client.from('chats').insert(chatData).select().single();
      final chatId = response['id'] as String;

      // Add participants
      final participantsData = participantIds.map((userId) => {
        'chat_id': chatId,
        'user_id': userId,
      }).toList();

      await _client.from('participants').insert(participantsData);

      return ChatModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map((messages) => messages.map((m) => MessageModel.fromJson(m)).toList());
  }

  Future<MessageModel> sendMessage({
    required String chatId,
    required String content,
    required String senderId,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final messageData = {
        'chat_id': chatId,
        'content': content,
        'sender_id': senderId,
        'type': type.toString().split('.').last,
        'created_at': DateTime.now().toIso8601String(),
        'metadata': metadata,
      };

      final response = await _client
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      // Update last message in chat
      await _client.from('chats').update({
        'last_message_content': content,
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('id', chatId);

      return MessageModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // User Methods
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .or('name.ilike.%$query%,email.ilike.%$query%')
          .limit(10);

      return (response as List).map((user) => UserModel.fromJson(user)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserPresence(String userId, bool isOnline) async {
    try {
      await _client.from('users').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }
}
