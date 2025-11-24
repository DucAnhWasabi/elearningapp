import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Để format ngày tháng
import '../data/semester_model.dart';
import '../data/semester_service.dart';

class SemesterListScreen extends StatelessWidget {
  SemesterListScreen({super.key});

  final SemesterService _service = SemesterService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Học kỳ"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSemesterDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<SemesterModel>>(
        stream: _service.getSemestersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final semesters = snapshot.data ?? [];

          if (semesters.isEmpty) {
            return const Center(child: Text("Chưa có học kỳ nào. Hãy tạo mới!"));
          }

          return ListView.builder(
            itemCount: semesters.length,
            itemBuilder: (context, index) {
              final sem = semesters[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: sem.isActive ? Colors.green : Colors.grey,
                    child: Icon(sem.isActive ? Icons.check : Icons.history, color: Colors.white),
                  ),
                  title: Text(sem.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${DateFormat('dd/MM/yyyy').format(sem.startDate)} - ${DateFormat('dd/MM/yyyy').format(sem.endDate)}"
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text("Chỉnh sửa")),
                      if (!sem.isActive)
                        const PopupMenuItem(value: 'active', child: Text("Đặt làm Học kỳ chính")),
                      const PopupMenuItem(value: 'delete', child: Text("Xóa", style: TextStyle(color: Colors.red))),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') _showSemesterDialog(context, sem);
                      if (value == 'delete') _confirmDelete(context, sem.id);
                      if (value == 'active') _service.setActiveSemester(sem.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Các hàm phụ trợ (Dialogs) ---

  void _showSemesterDialog(BuildContext context, SemesterModel? semester) {
    final nameCtrl = TextEditingController(text: semester?.name);
    DateTime start = semester?.startDate ?? DateTime.now();
    DateTime end = semester?.endDate ?? DateTime.now().add(const Duration(days: 120));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Dùng StatefulBuilder để cập nhật UI trong Dialog
          builder: (context, setState) {
            return AlertDialog(
              title: Text(semester == null ? "Thêm Học Kỳ" : "Sửa Học Kỳ"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Tên học kỳ (VD: Fall 2025)"),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030), initialDate: start);
                            if (date != null) setState(() => start = date);
                          },
                          child: Text("Bắt đầu:\n${DateFormat('dd/MM/yyyy').format(start)}"),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030), initialDate: end);
                            if (date != null) setState(() => end = date);
                          },
                          child: Text("Kết thúc:\n${DateFormat('dd/MM/yyyy').format(end)}"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty) return;
                    final newSem = SemesterModel(
                      id: semester?.id ?? '', // Nếu add mới thì ID sẽ rỗng ở đây, nhưng Firestore sẽ tự sinh nếu dùng .add()
                      name: nameCtrl.text,
                      startDate: start,
                      endDate: end,
                      isActive: semester?.isActive ?? false,
                    );

                    if (semester == null) {
                      _service.addSemester(newSem);
                    } else {
                      _service.updateSemester(newSem);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Lưu"),
                ),
              ],
            );
          }
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa học kỳ này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Không")),
          TextButton(
              onPressed: () {
                _service.deleteSemester(id);
                Navigator.pop(ctx);
              },
              child: const Text("Xóa", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}