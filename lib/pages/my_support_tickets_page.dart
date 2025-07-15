import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restfoodblindbox/models/message_model.dart'; // 引入 Message 模型
import 'package:restfoodblindbox/models/support_ticket_model.dart';
import 'package:restfoodblindbox/pages/chat_page.dart';
import 'package:restfoodblindbox/services/support_service.dart';

class MySupportTicketsPage extends StatefulWidget {
  const MySupportTicketsPage({super.key});

  @override
  State<MySupportTicketsPage> createState() => _MySupportTicketsPageState();
}

class _MySupportTicketsPageState extends State<MySupportTicketsPage> {
  late Future<List<SupportTicket>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = SupportService().fetchMyTickets();
  }

  void _refreshTickets() {
    setState(() {
      _ticketsFuture = SupportService().fetchMyTickets();
    });
  }

  void _navigateToChat(SupportTicket ticket) {
    // 導航到 ChatPage，並傳入必要的參數
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatPage(
        orderId: ticket.id, // 複用 orderId 參數來傳遞 ticketId
        recipientName: '與客服中心對話',
        chatContext: 'support', // 告訴 ChatPage 這是客服對話
      ),
    )).then((_) => _refreshTickets()); // 從聊天室返回後，刷新列表
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的客服案件'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTickets,
          )
        ],
      ),
      body: FutureBuilder<List<SupportTicket>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("載入失敗: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('您沒有任何客服案件紀錄'));
          }

          final tickets = snapshot.data!;
          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return ListTile(
                leading: Icon(
                  ticket.status == 'open' ? Icons.chat_bubble : Icons.check_circle,
                  color: ticket.status == 'open' ? Colors.amber.shade800 : Colors.green,
                ),
                title: Text(ticket.subject,
                    style: TextStyle(fontWeight: ticket.status == 'open' ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text('最後更新: ${DateFormat('yyyy/MM/dd').format(ticket.lastUpdatedAt.toDate())}'),
                onTap: () => _navigateToChat(ticket),
              );
            },
          );
        },
      ),
    );
  }
}