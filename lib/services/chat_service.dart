import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restfoodblindbox/models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Message>> getMessagesStream(String orderId) {
    return _firestore
        .collection('chats')
        .doc(orderId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  Future<void> sendMessage(String orderId, String text) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('使用者未登入');

    final messageData = {
      'senderId': currentUser.uid,
      'text': text,
      'timestamp': Timestamp.now(),
    };

    final chatDocRef = _firestore.collection('chats').doc(orderId);
    await chatDocRef.collection('messages').add(messageData);
    await chatDocRef.set({
      'lastMessage': text,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}