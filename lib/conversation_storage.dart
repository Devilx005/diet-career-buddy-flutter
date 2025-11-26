import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'conversation.dart';

class ConversationStorage {
  static const String _conversationsKey = 'saved_conversations';

  static Future<List<Conversation>> loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? conversationsJson = prefs.getString(_conversationsKey);

    if (conversationsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(conversationsJson);
      return decoded.map((json) => Conversation.fromJson(json)).toList();
    } catch (e) {
      print('Error loading conversations: $e');
      return [];
    }
  }

  static Future<void> saveConversations(List<Conversation> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      conversations.map((c) => c.toJson()).toList(),
    );
    await prefs.setString(_conversationsKey, encoded);
  }

  static Future<void> saveConversation(Conversation conversation) async {
    final conversations = await loadConversations();
    final index = conversations.indexWhere((c) => c.id == conversation.id);

    if (index != -1) {
      conversations[index] = conversation;
    } else {
      conversations.insert(0, conversation);
    }

    await saveConversations(conversations);
  }

  static Future<void> deleteConversation(String id) async {
    final conversations = await loadConversations();
    conversations.removeWhere((c) => c.id == id);
    await saveConversations(conversations);
  }
}
