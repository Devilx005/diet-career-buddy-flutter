import 'package:flutter/material.dart';
import 'conversation.dart';
import 'conversation_storage.dart';
import 'chat_view_screen.dart';
class RecentChatsScreen extends StatefulWidget {
  @override
  State<RecentChatsScreen> createState() => _RecentChatsScreenState();
}

class _RecentChatsScreenState extends State<RecentChatsScreen> {
  List<Conversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final convos = await ConversationStorage.loadConversations();
    setState(() => _conversations = convos);
  }

  Future<void> _deleteConversation(String id) async {
    await ConversationStorage.deleteConversation(id);
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text('Recent Chats'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _conversations.isEmpty
          ? Center(
        child: Text(
          'No saved chats yet',
          style: TextStyle(color: Colors.white38),
        ),
      )
          : ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final chat = _conversations[index];
          return Dismissible(
            key: Key(chat.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _deleteConversation(chat.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              leading: Icon(Icons.chat_bubble_outline, color: Colors.tealAccent),
              title: Text(
                chat.title,
                style: TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${chat.messages.length} messages • ${_formatDate(chat.createdAt)}',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
              onTap: () {
                // Open this conversation
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatViewScreen(conversation: chat),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}
