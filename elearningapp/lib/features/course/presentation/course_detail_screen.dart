import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../data/course_model.dart';
import '../../content/presentation/stream_tab.dart';
import '../../content/presentation/classwork_tab.dart';
import 'people_tab.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;
  final String userRole; // Để hiển thị khác nhau giữa GV và SV

  const CourseDetailScreen({super.key, required this.course, required this.userRole});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final isInstructor = widget.userRole == AppConstants.roleInstructor;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.code),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue[800],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue[800],
          tabs: const [
            Tab(text: "Stream"),
            Tab(text: "Classwork"),
            Tab(text: "People"),
          ],
        ),
        actions: [
          // Nếu là GV thì có nút Setting để chỉnh sửa khóa học
          if (isInstructor)
            IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: STREAM
          StreamTab(
            courseId: widget.course.id,
            userRole: widget.userRole,
          ),

          // TAB 2: CLASSWORK
          ClassworkTab(
            courseId: widget.course.id,
            userRole: widget.userRole,
          ),

          // TAB 3: PEOPLE
          PeopleTab(
            courseId: widget.course.id,
            userRole: widget.userRole,
          ),
        ],
      ),
    );
  }
}