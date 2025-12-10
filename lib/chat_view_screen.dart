import 'package:flutter/material.dart';
import '../conversation.dart';
import '../conversation_storage.dart';
import '../gemini_service.dart';
import '../auth_service.dart';

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

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    print('🔵 ChatViewScreen init for conversation ${widget.conversation.id}');
    _messages = List.from(widget.conversation.messages);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    print('🟣 _sendMessage called with: $text');

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

    try {
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

      // 1) Save updated local conversation
      await _saveConversation();
      print('✅ Local conversation saved');

      // 2) Save this Q&A pair to Firestore
      final chatId = await _authService.saveChatMessage(
        message: userMessage.text,
        response: assistantMessage.text,
        category: 'career_guidance',
      );
      print('✅ Firestore chat saved with id=$chatId');
    } catch (e) {
      print('❌ Error in _sendMessage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        title: Text(
          widget.conversation.title,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF10A37F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: _messages.isEmpty
                ? const Center(
              child: Text(
                'No messages',
                style: TextStyle(color: Colors.white38),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length +
                  (_currentResponse.isNotEmpty || _isLoading ? 1 : 0),
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
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
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
                      color: const Color(0xFF2D2D2D),
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
                          icon: const Icon(Icons.add, color: Colors.grey),
                          onPressed: () {},
                          padding: const EdgeInsets.all(8),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: !_isLoading,
                            maxLines: 3,
                            minLines: 1,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Continue conversation...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                            ),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic, color: Colors.grey),
                          onPressed: () {},
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed:
                  _isLoading ? null : () => _sendMessage(_controller.text),
                  backgroundColor:
                  _isLoading ? Colors.grey : const Color(0xFF10A37F),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.arrow_upward,
                      color: Colors.white, size: 20),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color:
          message.isUser ? const Color(0xFF10A37F) : const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (!isStreaming) ...[
              const SizedBox(height: 8),
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
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
