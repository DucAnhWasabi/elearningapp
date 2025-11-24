import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart'; // Đảm bảo bạn đã có model này

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. TẠO ID PHÒNG CHAT (QUAN TRỌNG NHẤT)
  // Logic: Luôn sắp xếp ID theo thứ tự A-Z.
  // Ví dụ: UserA và UserB luôn tạo ra phòng "UserA_UserB", bất kể ai gọi trước.
  Future<String> getOrCreateConversationId(String currentUserId, String targetUserId) async {
    List<String> ids = [currentUserId, targetUserId];
    ids.sort(); // <--- CHÌA KHÓA CỦA VẤN ĐỀ
    String conversationId = "${ids[0]}_${ids[1]}";

    // Tạo doc nếu chưa tồn tại (để lưu thông tin chung)
    final docRef = _db.collection('conversations').doc(conversationId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'participantIds': ids,
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return conversationId;
  }

  // 2. Gửi tin nhắn
  Future<void> sendMessage(String conversationId, MessageModel message) async {
    // Lưu tin nhắn vào sub-collection
    await _db.collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toMap());

    // Cập nhật tin nhắn cuối cùng bên ngoài
    await _db.collection('conversations').doc(conversationId).update({
      'lastMessage': message.content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Lấy tin nhắn (Real-time)
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _db.collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: true) // Tin mới nhất nằm dưới cùng (cho ListView reverse)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }
}