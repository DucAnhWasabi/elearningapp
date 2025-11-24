import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/data/user_model.dart';
import '../../chat/presentation/chat_screen.dart';

class PeopleTab extends StatelessWidget {
  final String courseId;
  final String userRole;

  PeopleTab({super.key, required this.courseId, required this.userRole});

  final _currentUserId = AuthService().currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Giảng Viên"),
          _buildInstructorTile(context),

          _buildSectionHeader("Sinh Viên"),
          _buildStudentList(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: TextStyle(color: Colors.blue[900], fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  // --- 1. HIỂN THỊ GIẢNG VIÊN (Dynamic Query) ---
  Widget _buildInstructorTile(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      // Tìm người có role là INSTRUCTOR
      future: FirebaseFirestore.instance
          .collection(AppConstants.collUsers)
          .where('role', isEqualTo: AppConstants.roleInstructor)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const ListTile(title: Text("Đang tải thông tin GV..."));

        if (snapshot.data!.docs.isEmpty) {
          return const ListTile(title: Text("Chưa có giảng viên"));
        }

        final instructor = UserModel.fromFirestore(snapshot.data!.docs.first);

        return ListTile(
          leading: CircleAvatar(backgroundColor: Colors.blue, child: Text(instructor.displayName?[0] ?? "G")),
          title: Text(instructor.displayName ?? "Giảng viên"),
          subtitle: Text(instructor.email),
          trailing: IconButton(
            icon: const Icon(Icons.message, color: Colors.blue),
            onPressed: () {
              // Nếu mình là GV thì chặn
              if (userRole == AppConstants.roleInstructor) return;

              // Nếu mình là SV -> Chat với ID thật vừa tìm được
              _openChat(context, instructor.id, instructor.displayName ?? "Giảng viên");
            },
          ),
        );
      },
    );
  }

  // --- 2. HIỂN THỊ DANH SÁCH SINH VIÊN ---
  Widget _buildStudentList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collEnrollments)
          .where('courseId', isEqualTo: courseId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text("Lớp chưa có sinh viên."));

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_,__) => const Divider(),
          itemBuilder: (context, index) {
            final enrollData = docs[index].data() as Map<String, dynamic>;
            final studentId = enrollData['userId'];

            // Lấy thông tin chi tiết từng SV
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection(AppConstants.collUsers).doc(studentId).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox.shrink();
                final user = UserModel.fromFirestore(userSnap.data!);

                // Logic hiển thị nút chat:
                // 1. Mình là GV -> Được chat với mọi SV (trừ chính mình nếu lỗi data)
                // 2. Mình là SV -> KHÔNG ĐƯỢC chat với SV khác.
                final bool isInstructor = userRole == AppConstants.roleInstructor;
                final bool isMe = user.id == _currentUserId;
                final bool canChat = isInstructor && !isMe;

                return ListTile(
                  leading: CircleAvatar(child: Text(user.displayName?[0] ?? "S")),
                  title: Text(user.displayName ?? "Student"),
                  subtitle: Text(user.email),
                  trailing: canChat
                      ? IconButton(
                    icon: const Icon(Icons.message, color: Colors.blue),
                    onPressed: () => _openChat(context, user.id, user.displayName ?? "Student"),
                  )
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  void _openChat(BuildContext context, String targetId, String targetName) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(targetUserId: targetId, targetUserName: targetName))
    );
  }
}