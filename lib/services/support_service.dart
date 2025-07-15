import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restfoodblindbox/models/message_model.dart';
import 'package:restfoodblindbox/models/support_ticket_model.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 建立一個新的客服案件，並發送第一則訊息
  Future<String> createNewTicket(String subject, String firstMessage) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('使用者未登入');

    final newTicketRef = _firestore.collection('supportTickets').doc();

    final ticketData = {
      'userId': currentUser.uid,
      'userName': currentUser.displayName ?? '未提供名稱',
      'userEmail': currentUser.email ?? '未提供 Email',
      'subject': subject,
      'status': 'open',
      'lastMessage': firstMessage,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };
    await newTicketRef.set(ticketData);

    final messageData = {
      'senderId': currentUser.uid,
      'text': firstMessage,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await newTicketRef.collection('messages').add(messageData);
    return newTicketRef.id;
  }

  /// 獲取當前登入者的所有客服案件
  Future<List<SupportTicket>> fetchMyTickets() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('使用者未登入');

    final snapshot = await _firestore
        .collection('supportTickets')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('lastUpdatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => SupportTicket.fromFirestore(doc)).toList();
  }

  // --- vvv 這是本次補上的、遺漏的方法 vvv ---

  /// 獲取特定案件的訊息串流
  Stream<List<Message>> getMessagesStream(String ticketId) {
    return _firestore
        .collection('supportTickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  /// 發送一則訊息到特定案件
  Future<void> sendMessage(String ticketId, String text) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('使用者未登入');

    final messageData = {
      'senderId': currentUser.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final ticketRef = _firestore.collection('supportTickets').doc(ticketId);
    await ticketRef.collection('messages').add(messageData);
    await ticketRef.update({
      'lastMessage': text,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
// --- ^^^ 新增到此結束 ^^^ ---
}