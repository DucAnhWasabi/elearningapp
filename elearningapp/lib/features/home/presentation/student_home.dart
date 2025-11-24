import 'package:flutter/material.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/data/user_model.dart';
import '../../auth/presentation/login_screen.dart';
import '../../course/data/course_model.dart';
import '../data/student_service.dart';
import '../../course/presentation/course_detail_screen.dart'; // Sẽ tạo ở Bước 3

class StudentHome extends StatelessWidget {
  final UserModel user;

  const StudentHome({super.key, required this.user});

  void _handleLogout(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentService = StudentService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Courses"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Text(user.displayName?[0] ?? "S", style: const TextStyle(color: Colors.white)),
          ),
          IconButton(onPressed: () => _handleLogout(context), icon: const Icon(Icons.logout)),
        ],
      ),
      body: FutureBuilder<List<CourseModel>>(
        future: studentService.getEnrolledCourses(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          final courses = snapshot.data ?? [];

          if (courses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Bạn chưa đăng ký khóa học nào."),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildCourseCard(context, course);
            },
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    // Tạo màu ngẫu nhiên hoặc cố định theo môn cho đẹp
    final cardColor = Colors.primaries[course.code.hashCode % Colors.primaries.length];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course, userRole: user.role)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner màu sắc
            Container(
              height: 100,
              color: cardColor,
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomLeft,
              child: Text(
                course.code,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            // Thông tin chi tiết
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Chủ đề: ${course.subject}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}