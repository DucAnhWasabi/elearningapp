import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_service.dart';
import '../data/announcement_model.dart';
import '../data/content_service.dart';

class StreamTab extends StatefulWidget {
  final String courseId;
  final String userRole;

  const StreamTab({super.key, required this.courseId, required this.userRole});

  @override
  State<StreamTab> createState() => _StreamTabState();
}

class _StreamTabState extends State<StreamTab> {
  final _contentCtrl = TextEditingController();
  final _contentService = ContentService();
  final _currentUser = AuthService().currentUser; // Lấy user hiện tại từ Firebase Auth

  bool get isInstructor => widget.userRole == AppConstants.roleInstructor;

  void _postAnnouncement() {
    if (_contentCtrl.text.trim().isEmpty) return;

    final newPost = AnnouncementModel(
      id: '', // Firestore tự sinh
      courseId: widget.courseId,
      authorName: "Giảng viên", // Thực tế nên lấy tên từ User Profile
      content: _contentCtrl.text.trim(),
      createdAt: DateTime.now(),
      viewerIds: [],
    );

    _contentService.createAnnouncement(newPost);
    _contentCtrl.clear();
    FocusScope.of(context).unfocus(); // Ẩn bàn phím
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Ô đăng bài (Chỉ hiện cho Instructor)
        if (isInstructor)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _contentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Thông báo điều gì đó cho lớp...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _postAnnouncement,
                  icon: const Icon(Icons.send),
                  label: const Text("Đăng tin"),
                )
              ],
            ),
          ),

        // 2. Danh sách thông báo
        Expanded(
          child: StreamBuilder<List<AnnouncementModel>>(
            stream: _contentService.getAnnouncements(widget.courseId),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined, size: 60, color: Colors.grey),
                      Text("Chưa có thông báo nào."),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];

                  // --- Logic Tracking: Nếu là SV và chưa xem -> Gọi API ---
                  if (!isInstructor && _currentUser != null) {
                    if (!post.viewerIds.contains(_currentUser!.uid)) {
                      // Gọi background, không cần await để tránh chặn UI
                      _contentService.markAsViewed(post.id, _currentUser!.uid);
                    }
                  }
                  // --------------------------------------------------------

                  return _buildPostCard(post);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(AnnouncementModel post) {
    final bool isSeen = (_currentUser != null) && post.viewerIds.contains(_currentUser!.uid);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(post.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                if (isInstructor)
                // Giảng viên xem được bao nhiêu người đã đọc
                  Chip(
                    label: Text("${post.viewerIds.length} đã xem"),
                    backgroundColor: Colors.blue[50],
                    labelStyle: TextStyle(color: Colors.blue[800], fontSize: 10),
                  )
                else
                // Sinh viên thấy trạng thái "Mới" nếu vừa load xong
                  isSeen
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
                      : const Chip(label: Text("MỚI"), backgroundColor: Colors.red, labelStyle: TextStyle(color: Colors.white, fontSize: 10))
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}