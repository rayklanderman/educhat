import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase project credentials
  static const String projectUrl = 'https://fvifrirxholnauxvtilo.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ2aWZyaXJ4aG9sbmF1eHZ0aWxvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQwMzQzNTAsImV4cCI6MjA0OTYxMDM1MH0.9TXFNxnFBupQbgiRNE9YTGMi0nl-qtlvj-2PMBD0Aqs';

  // Initialize Supabase client
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: projectUrl,
      anonKey: anonKey,
      debug: true, // Set to false for production
    );
  }

  // Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  // Get current user
  static User? get currentUser => client.auth.currentUser;

  // Database table names
  static const String users = 'users';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String files = 'files';
  static const String chatParticipants = 'chat_participants';

  // Storage bucket names
  static const String chatFilesBucket = 'chat-files';
}
