import 'package:flutter/material.dart';
import '../conversation.dart';
import '../conversation_storage.dart';
import '../gemini_service.dart';

class ChatViewScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatViewScreen({Key? key, required this.conversation}) : super(key: key);

  @override
  State<ChatViewScreen> createState() => _ChatViewScreenState();
}

class _ChatViewScreenState extends State<ChatViewScreen> {
  late List<Message> _messages;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentResponse = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.conversation.messages);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = Message(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _currentResponse = '';
      _isLoading = true;
    });

    _scrollToBottom();

    await GeminiService.chatStreaming(text, (chunk) {
      setState(() {
        _currentResponse = chunk;
        _isLoading = false;
      });
      _scrollToBottom();
    });

    final assistantMessage = Message(
      text: _currentResponse,
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(assistantMessage);
      _currentResponse = '';
    });

    // Save updated conversation
    await _saveConversation();
  }

  Future<void> _saveConversation() async {
    final updatedConversation = Conversation(
      id: widget.conversation.id,
      title: widget.conversation.title,
      createdAt: widget.conversation.createdAt,
      messages: _messages,
    );
    await ConversationStorage.saveConversation(updatedConversation);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Color(0xFF212121),
        title: Text(
          widget.conversation.title,
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF10A37F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Text(
                'No messages',
                style: TextStyle(color: Colors.white38),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_currentResponse.isNotEmpty || _isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                } else {
                  return _buildMessageBubble(
                    Message(
                      text: _isLoading ? 'Thinking...' : _currentResponse,
                      isUser: false,
                      timestamp: DateTime.now(),
                    ),
                    isStreaming: true,
                  );
                }
              },
            ),
          ),

          // Input area
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(
                top: BorderSide(color: Colors.white10),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.grey),
                          onPressed: () {},
                          padding: EdgeInsets.all(8),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: !_isLoading,
                            maxLines: 3,
                            minLines: 1,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Continue conversation...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            ),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.mic, color: Colors.grey),
                          onPressed: () {},
                          padding: EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _isLoading ? null : () => _sendMessage(_controller.text),
                  backgroundColor: _isLoading ? Colors.grey : Color(0xFF10A37F),
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, {bool isStreaming = false}) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? Color(0xFF10A37F) : Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (!isStreaming) ...[
              SizedBox(height: 8),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: message.isUser ? Colors.white70 : Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
