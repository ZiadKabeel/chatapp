import 'package:chating_app/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverEmail;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late final String _currentUserId;

  late final String _chatId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _chatId = _chatService.getChatId(_currentUserId, widget.receiverId);
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final message = _messageCtrl.text.trim();
    if (message.isEmpty) return;

    _messageCtrl.clear();

    try {
      await _chatService.sendMessage(widget.receiverId, message);
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: StreamBuilder<DocumentSnapshot>(
        stream: _chatService.getUserStreamById(widget.receiverId),
        builder: (context, snapshot) {
          String statusText = 'Connecting...';
          Color statusColor = Colors.grey;

          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final bool isOnline = userData['isOnline'] ?? false;

            if (isOnline) {
              statusText = 'Online';
              statusColor = Colors.greenAccent;
            } else {
              final Timestamp? lastSeen = userData['lastSeen'] as Timestamp?;
              if (lastSeen != null) {
                statusText = 'Last seen ${_formatTimestamp(lastSeen)}';
              } else {
                statusText = 'Offline';
              }
              statusColor = Colors.grey.shade400;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.receiverName,
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                statusText,
                style: TextStyle(fontSize: 12, color: statusColor),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.streamMessages(_chatId),
      builder: (context, snapshot) {
        // Handle error state
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading messages'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Say hello to ${widget.receiverName}!',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data() as Map<String, dynamic>;
            final bool isCurrentUser = messageData['senderId'] == _currentUserId;
            return _buildMessageBubble(messageData, isCurrentUser);
          },
        );
      },
    );
  }

  
  Widget _buildMessageBubble(Map<String, dynamic> data, bool isCurrentUser) {
    final alignment =
        isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor =
        isCurrentUser ? Colors.blue.shade600 : Colors.grey.shade200;
    final textColor = isCurrentUser ? Colors.white : Colors.black87;
    final timeColor =
        isCurrentUser ? Colors.white70 : Colors.grey.shade600;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isCurrentUser ? const Radius.circular(16) : Radius.zero,
      bottomRight: isCurrentUser ? Radius.zero : const Radius.circular(16),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                
                Text(
                  data['message'] ?? '',
                  style: TextStyle(color: textColor, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(data['timestamp'] as Timestamp?),
                  style: TextStyle(color: timeColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Message text field
            Expanded(
              child: TextField(
                controller: _messageCtrl,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                // Allow sending with Enter key
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Container(
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
