import 'package:flutter/material.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/data/user_model.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/dashboard_service.dart'; // Import Service mới
import '../../semester/presentation/semester_list_screen.dart';
import '../../course/presentation/course_management_screen.dart';
import '../../student/presentation/student_management_screen.dart';

class InstructorDashboard extends StatefulWidget {
  final UserModel user;

  const InstructorDashboard({super.key, required this.user});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  final DashboardService _dashboardService = DashboardService();
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = _dashboardService.fetchStats();
    });
  }

  void _handleLogout(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Instructor Dashboard"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStats, // Nút làm mới dữ liệu
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),

            // --- PHẦN THỐNG KÊ (REAL-TIME) ---
            const Text(
              "Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            FutureBuilder<DashboardStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                // Mặc định hiển thị loading hoặc 0
                int courses = 0;
                int students = 0;
                int asms = 0;
                int pending = 0;
                bool isLoading = snapshot.connectionState == ConnectionState.waiting;

                if (snapshot.hasData) {
                  courses = snapshot.data!.activeCourses;
                  students = snapshot.data!.totalStudents;
                  asms = snapshot.data!.totalAssignments;
                  pending = snapshot.data!.pendingGrades;
                }

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard("Active Courses", isLoading ? "..." : "$courses", Colors.orange, Icons.book),
                    _buildStatCard("Total Students", isLoading ? "..." : "$students", Colors.green, Icons.people),
                    _buildStatCard("Assignments", isLoading ? "..." : "$asms", Colors.purple, Icons.assignment),
                    _buildStatCard("Pending Grade", isLoading ? "..." : "$pending", Colors.red, Icons.grading),
                  ],
                );
              },
            ),
            // ----------------------------------

            const SizedBox(height: 24),
            const Text(
              "Management Tools",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildActionTile(
                context, "Manage Semesters", "Create, Edit, Archive semesters", Icons.calendar_today, Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => SemesterListScreen()))
            ),
            _buildActionTile(
                context, "Manage Courses & Groups", "Setup classes for IT Faculty", Icons.class_, Colors.indigo,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseManagementScreen()))
            ),
            _buildActionTile(
                context, "Student Accounts", "Import CSV, Create users", Icons.person_add, Colors.teal,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentManagementScreen()))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue[200],
          child: Text(widget.user.displayName?[0] ?? "A", style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back,", style: TextStyle(color: Colors.grey[600])),
            Text(widget.user.displayName ?? "Instructor", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}