import 'package:flutter/material.dart';
import 'gemini_service.dart';
import 'conversation.dart';

class TemporaryChatPanel extends StatefulWidget {
  final VoidCallback onClose;

  const TemporaryChatPanel({Key? key, required this.onClose}) : super(key: key);

  @override
  State<TemporaryChatPanel> createState() => _TemporaryChatPanelState();
}

class _TemporaryChatPanelState extends State<TemporaryChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  String _currentResponse = '';
  bool _isLoading = false;

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
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

    setState(() {
      _messages.add(Message(
        text: _currentResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _currentResponse = '';
    });
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

  void _clearChat() {
    setState(() {
      _messages.clear();
      _currentResponse = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        border: Border(left: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble, color: Color(0xFF10A37F), size: 20),
                SizedBox(width: 8),
                Text(
                  'Quick Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white70, size: 20),
                  tooltip: 'Clear chat',
                  onPressed: _clearChat,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _messages.isEmpty && _currentResponse.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_outlined, color: Colors.white24, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Start a quick conversation',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This chat won\'t be saved',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(12),
              itemCount: _messages.length + (_currentResponse.isNotEmpty || _isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                } else {
                  return _buildMessageBubble(
                    Message(
                      text: _isLoading ? 'Typing...' : _currentResponse,
                      isUser: false,
                      timestamp: DateTime.now(),
                    ),
                    isStreaming: true,
                  );
                }
              },
            ),
          ),

          // Input
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isLoading,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ask anything...',
                      hintStyle: TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    onSubmitted: _sendMessage,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey : Color(0xFF10A37F),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _isLoading ? null : () => _sendMessage(_controller.text),
                  ),
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
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: message.isUser
              ? Color(0xFF10A37F).withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
