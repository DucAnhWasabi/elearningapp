import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_service.dart';
import '../data/assignment_model.dart';
import '../data/submission_model.dart';
import '../data/assignment_service.dart';

// --- ĐÃ CHUYỂN THÀNH STATEFUL WIDGET ---
class AssignmentDetailScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final String userRole;

  const AssignmentDetailScreen({super.key, required this.assignment, required this.userRole});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final _authService = AuthService();
  final _assignmentService = AssignmentService();

  // Biến để hiện vòng xoay loading
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final isInstructor = widget.userRole == AppConstants.roleInstructor;

    return Scaffold(
      appBar: AppBar(title: Text(widget.assignment.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 32),
            if (isInstructor)
              _buildInstructorView(context)
            else
              _buildStudentView(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Hạn nộp: ${DateFormat('dd/MM HH:mm').format(widget.assignment.dueDate)}",
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            Chip(label: Text(widget.assignment.allowLate ? "Cho phép nộp trễ" : "Không nộp trễ")),
          ],
        ),
        const SizedBox(height: 10),
        const Text("Hướng dẫn:", style: TextStyle(fontWeight: FontWeight.bold)),
        Text(widget.assignment.instructions, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  // --- GIAO DIỆN SINH VIÊN (Đã sửa lỗi) ---
  Widget _buildStudentView(BuildContext context) {
    final studentId = _authService.currentUser?.uid;

    if (studentId == null) return const Text("Lỗi: Không tìm thấy thông tin người dùng");

    final linkCtrl = TextEditingController();

    return StreamBuilder<SubmissionModel?>(
      stream: _assignmentService.getMySubmission(widget.assignment.id, studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final submission = snapshot.data;
        final isSubmitted = submission != null;

        if (isSubmitted) {
          linkCtrl.text = submission.fileUrl;
        }

        return Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bài làm của bạn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (isSubmitted) ...[
                  ListTile(
                    title: Text(submission.status,
                        style: TextStyle(
                            color: submission.grade != null ? Colors.green : Colors.blue,
                            fontWeight: FontWeight.bold
                        )
                    ),
                    subtitle: submission.feedback != null
                        ? Text("Nhận xét: ${submission.feedback}")
                        : const Text("Đang đợi chấm điểm"),
                    leading: const Icon(Icons.check_circle),
                  ),
                  const Divider(),
                ],

                TextField(
                  controller: linkCtrl,
                  decoration: const InputDecoration(
                      labelText: "Dán đường dẫn bài làm (Google Drive, GitHub...)",
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white
                  ),
                  enabled: submission?.grade == null,
                ),
                const SizedBox(height: 16),

                if (submission?.grade == null)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null // Vô hiệu hóa nút khi đang nộp
                          : () {
                        if (linkCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng dán đường dẫn!")));
                          return;
                        }
                        _submitLink(context, linkCtrl.text);
                      },
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: Text(isSubmitted ? "Cập nhật bài nộp" : "Nộp bài"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white
                      ),
                    ),
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HÀM NỘP BÀI ĐÃ SỬA ---
  void _submitLink(BuildContext context, String link) async {
    setState(() => _isSubmitting = true); // Bật loading

    try {
      final currentUser = AuthService().currentUser!;

      final submission = SubmissionModel(
        id: '',
        assignmentId: widget.assignment.id,
        studentId: currentUser.uid,
        studentName: currentUser.displayName ?? "Student", // Cần đảm bảo User Profile có tên
        fileUrl: link,
        fileName: "Link Submission",
        submittedAt: DateTime.now(),
      );

      await _assignmentService.submitAssignment(submission);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã nộp bài thành công!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false); // Tắt loading
    }
  }

  // --- GIAO DIỆN GIẢNG VIÊN (Giữ nguyên logic) ---
  Widget _buildInstructorView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Danh sách bài nộp", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        StreamBuilder<List<SubmissionModel>>(
          stream: _assignmentService.getAllSubmissions(widget.assignment.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final subs = snapshot.data!;

            if (subs.isEmpty) return const Text("Chưa có sinh viên nào nộp bài.");

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subs.length,
              itemBuilder: (context, index) {
                final sub = subs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: CircleAvatar(child: Text(sub.studentName.isNotEmpty ? sub.studentName[0] : "S")),
                    title: Text(sub.studentName),
                    subtitle: Text(DateFormat('dd/MM HH:mm').format(sub.submittedAt)),
                    trailing: sub.grade != null
                        ? Text("${sub.grade} đ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
                        : const Text("Chưa chấm", style: TextStyle(color: Colors.red)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => launchUrl(Uri.parse(sub.fileUrl)),
                              child: Row(
                                children: [
                                  const Icon(Icons.link, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(sub.fileUrl, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _GradeForm(submission: sub, onGrade: _assignmentService.gradeSubmission),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        )
      ],
    );
  }
}

class _GradeForm extends StatefulWidget {
  final SubmissionModel submission;
  final Function(String, double, String) onGrade;
  const _GradeForm({required this.submission, required this.onGrade});

  @override
  State<_GradeForm> createState() => _GradeFormState();
}

class _GradeFormState extends State<_GradeForm> {
  final _gradeCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.submission.grade != null) _gradeCtrl.text = widget.submission.grade.toString();
    if (widget.submission.feedback != null) _feedbackCtrl.text = widget.submission.feedback!;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: TextField(
            controller: _gradeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Điểm", border: OutlineInputBorder()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _feedbackCtrl,
            decoration: const InputDecoration(labelText: "Nhận xét", border: OutlineInputBorder()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.save, color: Colors.blue),
          onPressed: () {
            final grade = double.tryParse(_gradeCtrl.text);
            if (grade != null) {
              widget.onGrade(widget.submission.id, grade, _feedbackCtrl.text);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu điểm!")));
            }
          },
        )
      ],
    );
  }
}