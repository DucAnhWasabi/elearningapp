import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/user_model.dart';
import '../data/enrollment_service.dart';

class GroupDetailScreen extends StatelessWidget {
  final String courseId;
  final String groupId;
  final String groupName;

  GroupDetailScreen({
    super.key,
    required this.courseId,
    required this.groupId,
    required this.groupName
  });

  final EnrollmentService _service = EnrollmentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStudentDialog(context),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          // Header thống kê
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo[50],
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.indigo),
                const SizedBox(width: 10),
                Expanded(child: Text("Danh sách sinh viên lớp $groupName")),
              ],
            ),
          ),

          // Danh sách sinh viên
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _service.getStudentsInGroup(groupId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final students = snapshot.data!;
                if (students.isEmpty) return const Center(child: Text("Chưa có sinh viên nào."));

                return ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(student.displayName?[0] ?? "S")),
                      title: Text(student.displayName ?? "No Name"),
                      subtitle: Text("${student.studentCode ?? '--'} | ${student.email}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _confirmRemove(context, student),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Dialog Thêm sinh viên ---
  void _showAddStudentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SearchStudentSheet(
        onSelect: (user) async {
          try {
            await _service.enrollStudent(courseId, groupId, user.id);
            if(context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Đã thêm ${user.displayName} vào nhóm!"))
              );
            }
          } catch (e) {
            if(context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red)
              );
            }
          }
        },
      ),
    );
  }

  void _confirmRemove(BuildContext context, UserModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa sinh viên"),
        content: Text("Xóa ${student.displayName} khỏi nhóm này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              _service.removeStudent(groupId, student.id);
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }
}

// Widget con để tìm kiếm sinh viên (Nằm trong BottomSheet)
class _SearchStudentSheet extends StatefulWidget {
  final Function(UserModel) onSelect;
  const _SearchStudentSheet({required this.onSelect});

  @override
  State<_SearchStudentSheet> createState() => _SearchStudentSheetState();
}

class _SearchStudentSheetState extends State<_SearchStudentSheet> {
  final _searchCtrl = TextEditingController();
  final _service = EnrollmentService();
  List<UserModel> _results = [];
  bool _loading = false;

  void _search() async {
    if (_searchCtrl.text.isEmpty) return;

    // 1. Bắt đầu loading
    setState(() => _loading = true);

    try {
      // 2. Gọi API
      final res = await _service.searchStudentsToAdd(_searchCtrl.text.trim());

      // 3. Nếu thành công
      if (mounted) {
        setState(() {
          _results = res;
          _loading = false;
        });

        if (res.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Không tìm thấy sinh viên nào."))
          );
        }
      }
    } catch (e) {
      // 4. QUAN TRỌNG: Nếu lỗi, phải tắt loading và in lỗi ra
      print("LỖI SEARCH: $e"); // <-- Xem lỗi ở Console
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SizedBox(
        height: 500,
        child: Column(
          children: [
            const Text("Thêm Sinh Viên", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(hintText: "Nhập email sinh viên..."),
                  ),
                ),
                IconButton(onPressed: _search, icon: const Icon(Icons.search)),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading) const CircularProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final u = _results[index];
                  return ListTile(
                    title: Text(u.displayName ?? ""),
                    subtitle: Text(u.email),
                    trailing: const Icon(Icons.add),
                    onTap: () => widget.onSelect(u),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}