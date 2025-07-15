import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String id;
  final String subject;
  final String status;
  final Timestamp lastUpdatedAt;

  SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.lastUpdatedAt,
  });

  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicket(
      id: doc.id,
      subject: data['subject'] ?? '無主旨',
      status: data['status'] ?? 'closed',
      lastUpdatedAt: data['lastUpdatedAt'] ?? Timestamp.now(),
    );
  }
}