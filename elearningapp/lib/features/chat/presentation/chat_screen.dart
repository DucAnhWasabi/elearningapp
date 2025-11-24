import 'package:flutter/material.dart';
import '../../auth/data/auth_service.dart';
import '../data/chat_service.dart';
import '../data/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const ChatScreen({super.key, required this.targetUserId, required this.targetUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _msgCtrl = TextEditingController();
  final _currentUserId = AuthService().currentUser!.uid; // ID của TÔI
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() async {
    // 1. Lấy thông tin từ Auth
    final currentUser = AuthService().currentUser;
    if (currentUser == null || currentUser.email == null) return;

    String myRealId = currentUser.uid; // Mặc định là Auth UID

    // 2. "CẦU NỐI EMAIL": Tìm ID thật trong Firestore dựa vào Email
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users') // Hoặc AppConstants.collUsers
          .where('email', isEqualTo: currentUser.email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        // A HA! Tìm thấy bản ghi Firestore khớp email rồi!
        // Dùng ID của bản ghi này thay vì Auth UID
        myRealId = userQuery.docs.first.id;
        // print("✅ Đã Map AuthUID (${currentUser.uid}) -> FirestoreID ($myRealId)");
      } else {
        print("⚠️ Không tìm thấy user trong Firestore, dùng tạm AuthUID");
      }
    } catch (e) {
      print("Lỗi tìm ID: $e");
    }

    // 3. Bây giờ mới tạo ID phòng chat bằng "myRealId"
    final id = await _chatService.getOrCreateConversationId(myRealId, widget.targetUserId);

    // --- DEBUG LOG ---
    // print("🔴 CHAT DEBUG START ----------------");
    // print("🔴 EMAIL: ${currentUser.email}");
    // print("🔴 ME (Real Firestore ID): $myRealId");
    // print("🔴 TARGET: ${widget.targetUserId}");
    // print("🔴 ROOM ID: $id");
    // print("🔴 ---------------------------------");

    if (mounted) setState(() => _conversationId = id);
  }

  void _send() {
    if (_msgCtrl.text.trim().isEmpty || _conversationId == null) return;

    final msg = MessageModel(
      id: '',
      senderId: _currentUserId,
      senderName: AuthService().currentUser!.displayName ?? "Me",
      content: _msgCtrl.text.trim(),
      sentAt: DateTime.now(),
    );

    _chatService.sendMessage(_conversationId!, msg);
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat với ${widget.targetUserName}")),
      body: Column(
        children: [
          Expanded(
            child: _conversationId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(_conversationId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final msgs = snapshot.data!;
                if (msgs.isEmpty) return const Center(child: Text("Hãy bắt đầu cuộc trò chuyện!"));

                return ListView.builder(
                  reverse: true, // Tin mới ở dưới cùng
                  itemCount: msgs.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final msg = msgs[index];
                    final isMe = msg.senderId == _currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[600] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content,
                              style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 16),
                            ),
                            // Có thể thêm hiển thị giờ nếu muốn
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              decoration: const InputDecoration(
                  hintText: "Nhập tin nhắn...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  filled: true,
                  fillColor: Colors.white
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _send,
            ),
          )
        ],
      ),
    );
  }
}