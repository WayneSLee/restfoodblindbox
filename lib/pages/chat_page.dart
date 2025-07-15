import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restfoodblindbox/models/message_model.dart';
import 'package:restfoodblindbox/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:restfoodblindbox/services/support_service.dart';

class ChatPage extends StatefulWidget {
  final String orderId;
  final String recipientName; // 接收對方的名稱，顯示在 AppBar 上
  final String chatContext;

  const ChatPage({
    super.key,
    required this.orderId,
    required this.recipientName,
    this.chatContext = 'order',
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      if (widget.chatContext == 'support') {
        // 如果是客服對話，呼叫 SupportService
        SupportService().sendMessage(widget.orderId, _messageController.text);
      } else {
        // 否則，呼叫原本的 ChatService
        ChatService().sendMessage(widget.orderId, _messageController.text);
      }
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // 短暫延遲後滾動，確保 ListView 已經 build 完成
    Future.delayed(const Duration(milliseconds: 300), () {
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
      appBar: AppBar(
        title: Text(widget.recipientName),
      ),
      body: Column(
        children: [
          // 訊息列表
          Expanded(
            child: StreamBuilder<List<Message>>(
              // 根據 chatContext，決定要監聽哪個 Service
              stream: widget.chatContext == 'support'
                  ? SupportService().getMessagesStream(widget.orderId)
                  : ChatService().getMessagesStream(widget.orderId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('發生錯誤: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('開始對話吧！'));
                }

                // 當有新訊息時，自動滾動到底部
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data![index];
                    return _buildMessageItem(message);
                  },
                );
              },
            ),
          ),
          // 輸入框
          _buildMessageInput(),
        ],
      ),
    );
  }

  // 建立單一訊息氣泡的 Widget
  Widget _buildMessageItem(Message message) {
    // 判斷這則訊息是否是目前登入的使用者發送的
    final bool isCurrentUser = message.senderId == _auth.currentUser?.uid;

    return Container(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment:
        isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(message.timestamp.toDate()),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          )
        ],
      ),
    );
  }

  // 建立底部輸入框的 Widget
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: '輸入訊息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}