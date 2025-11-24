import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../semester/data/semester_model.dart';
import '../../semester/data/semester_service.dart';
import '../data/course_model.dart';
import '../data/course_service.dart';
import 'group_detail_screen.dart';
import 'course_detail_screen.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final SemesterService _semesterService = SemesterService();
  final CourseService _courseService = CourseService();

  SemesterModel? _selectedSemester;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Khóa học & Lớp"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Semester Selector
          _buildSemesterDropdown(),
          const Divider(height: 1),

          // 2. Course List
          Expanded(
            child: _selectedSemester == null
                ? const Center(child: Text("Vui lòng chọn một học kỳ"))
                : _buildCourseList(),
          ),
        ],
      ),
      floatingActionButton: _selectedSemester != null
          ? FloatingActionButton.extended(
        onPressed: () => _showAddCourseDialog(),
        label: const Text("Thêm Môn"),
        icon: const Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildSemesterDropdown() {
    return StreamBuilder<List<SemesterModel>>(
      stream: _semesterService.getSemestersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final semesters = snapshot.data!;

        // Auto select active semester if none selected
        if (_selectedSemester == null && semesters.isNotEmpty) {
          // Tìm cái đang active, nếu ko có lấy cái đầu
          try {
            _selectedSemester = semesters.firstWhere((s) => s.isActive);
          } catch (_) {
            if(semesters.isNotEmpty) _selectedSemester = semesters.first;
          }
        }

        return Container(
          padding: const EdgeInsets.all(12),
          color: Colors.indigo[50],
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.indigo),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<SemesterModel>(
                  isExpanded: true,
                  value: _selectedSemester,
                  underline: const SizedBox(),
                  items: semesters.map((sem) {
                    return DropdownMenuItem(
                      value: sem,
                      child: Text("${sem.name} ${sem.isActive ? '(Active)' : ''}"),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedSemester = val),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseList() {
    return StreamBuilder<List<CourseModel>>(
      stream: _courseService.getCoursesBySemester(_selectedSemester!.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final courses = snapshot.data!;
        if (courses.isEmpty) return const Center(child: Text("Chưa có môn học nào trong học kỳ này."));

        return ListView.builder(
          itemCount: courses.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final course = courses[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Text(course.code.substring(0, 1)),
                ),
                title: Text("${course.code} - ${course.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Chủ đề: ${course.subject}"),
                children: [
                  // 1. Nút MỚI để vào màn hình Stream/Classwork
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.indigo[50],
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CourseDetailScreen(
                                course: course,
                                userRole: AppConstants.roleInstructor // <-- Cấp quyền Giảng viên
                            ))
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text("Truy cập lớp học (Đăng bài/Tạo bài tập)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  // 2. Danh sách nhóm (Code cũ)
                  _buildGroupList(course.id),

                  // 3. Nút tạo nhóm (Code cũ)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton.icon(
                      onPressed: () => _showAddGroupDialog(course.id),
                      icon: const Icon(Icons.group_add),
                      label: const Text("Tạo nhóm lớp mới"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Hiển thị danh sách nhóm nhỏ bên trong ExpansionTile
  Widget _buildGroupList(String courseId) {
    return StreamBuilder<List<GroupModel>>(
      stream: _courseService.getGroupsByCourse(courseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final groups = snapshot.data!;

        return Column(
          children: groups.map((group) => ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 72, right: 16),
            title: Text(group.name),
            subtitle: Text("${group.studentCount} sinh viên"),
            // --- CODE MỚI ---
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GroupDetailScreen(
                    courseId: group.courseId,
                    groupId: group.id,
                    groupName: group.name,
                  ))
              );
            },
            // ----------------
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _courseService.deleteGroup(group.id),
            ),
          )).toList(),
        );
      },
    );
  }

  // --- Dialogs ---

  void _showAddCourseDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedSubject = AllowedSubjects.list.first;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Thêm Môn Học Mới"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Mã môn (VD: INT3306)")),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Tên môn (VD: Lập trình Web)")),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedSubject,
                decoration: const InputDecoration(labelText: "Chủ đề (Bắt buộc IT)"),
                items: AllowedSubjects.list.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => selectedSubject = val!,
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
              _courseService.addCourse(CourseModel(
                id: '', semesterId: _selectedSemester!.id,
                code: codeCtrl.text, name: nameCtrl.text,
                subject: selectedSubject, description: '',
              ));
              Navigator.pop(ctx);
            },
            child: const Text("Tạo Môn"),
          )
        ],
      ),
    );
  }

  void _showAddGroupDialog(String courseId) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tạo Nhóm Lớp"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: "Tên nhóm (VD: Nhóm 1 - Thứ 2)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              _courseService.addGroup(GroupModel(
                  id: '', courseId: courseId, name: nameCtrl.text
              ));
              Navigator.pop(ctx);
            },
            child: const Text("Tạo Nhóm"),
          )
        ],
      ),
    );
  }
}