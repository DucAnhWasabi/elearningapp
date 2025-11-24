import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../data/assignment_model.dart';
import '../data/assignment_service.dart';
import 'assignment_detail_screen.dart';

class ClassworkTab extends StatelessWidget {
  final String courseId;
  final String userRole;

  ClassworkTab({super.key, required this.courseId, required this.userRole});

  final _assignmentService = AssignmentService();

  @override
  Widget build(BuildContext context) {
    final isInstructor = userRole == AppConstants.roleInstructor;

    return Scaffold(
      floatingActionButton: isInstructor
          ? FloatingActionButton.extended(
        onPressed: () => _showCreateAssignmentDialog(context),
        label: const Text("Giao bài tập"),
        icon: const Icon(Icons.add),
      )
          : null,
      body: StreamBuilder<List<AssignmentModel>>(
        stream: _assignmentService.getAssignments(courseId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final assignments = snapshot.data!;
          if (assignments.isEmpty) {
            return const Center(child: Text("Chưa có bài tập nào."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final asm = assignments[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.assignment, color: Colors.white),
                  ),
                  title: Text(asm.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Hạn: ${DateFormat('dd/MM HH:mm').format(asm.dueDate)}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // --- CODE MỚI ---
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AssignmentDetailScreen(
                            assignment: asm,
                            userRole: userRole
                        ))
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateAssignmentDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final instructCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7)); // Mặc định 1 tuần

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Tạo Bài Tập Mới"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Tiêu đề")),
                    const SizedBox(height: 12),
                    TextField(controller: instructCtrl, decoration: const InputDecoration(labelText: "Hướng dẫn"), maxLines: 3),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text("Hạn nộp:"),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(dueDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030), initialDate: dueDate);
                        if (date != null) {
                          // ignore: use_build_context_synchronously
                          final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (time != null) {
                            setState(() => dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                          }
                        }
                      },
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) return;
                    _assignmentService.createAssignment(AssignmentModel(
                        id: '', courseId: courseId,
                        title: titleCtrl.text,
                        instructions: instructCtrl.text,
                        dueDate: dueDate
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text("Giao bài"),
                )
              ],
            );
          }
      ),
    );
  }
}