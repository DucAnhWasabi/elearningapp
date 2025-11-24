import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import 'assignment_model.dart';
import 'submission_model.dart';

class AssignmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // BỎ: final FirebaseStorage _storage ... (Không dùng nữa)

  // 1. Lấy danh sách bài tập (Giữ nguyên)
  Stream<List<AssignmentModel>> getAssignments(String courseId) {
    return _db.collection(AppConstants.collAssignments)
        .where('courseId', isEqualTo: courseId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AssignmentModel.fromFirestore(d)).toList());
  }

  // 2. Tạo bài tập (Giữ nguyên)
  Future<void> createAssignment(AssignmentModel assignment) async {
    await _db.collection(AppConstants.collAssignments).add(assignment.toMap());
  }

  // 3. Nộp bài (Lưu Link thay vì File)
  Future<void> submitAssignment(SubmissionModel submission) async {
    // Check xem đã nộp chưa, nếu rồi thì update (cho phép nộp lại)
    final q = await _db.collection(AppConstants.collSubmissions)
        .where('assignmentId', isEqualTo: submission.assignmentId)
        .where('studentId', isEqualTo: submission.studentId)
        .get();

    if (q.docs.isNotEmpty) {
      // Update bài cũ
      await q.docs.first.reference.update({
        'fileUrl': submission.fileUrl, // Ở đây fileUrl sẽ chứa LINK (http...)
        'submittedAt': Timestamp.now(),
      });
    } else {
      // Tạo bài mới
      await _db.collection(AppConstants.collSubmissions).add(submission.toMap());
    }
  }

  // 4. Lấy bài nộp của TÔI (Sinh viên)
  Stream<SubmissionModel?> getMySubmission(String assignmentId, String studentId) {
    return _db.collection(AppConstants.collSubmissions)
        .where('assignmentId', isEqualTo: assignmentId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty ? SubmissionModel.fromFirestore(snap.docs.first) : null);
  }

  // 5. Lấy TẤT CẢ bài nộp của lớp (Giảng viên)
  Stream<List<SubmissionModel>> getAllSubmissions(String assignmentId) {
    return _db.collection(AppConstants.collSubmissions)
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SubmissionModel.fromFirestore(d)).toList());
  }

  // 6. Chấm điểm (Giảng viên)
  Future<void> gradeSubmission(String submissionId, double grade, String feedback) async {
    await _db.collection(AppConstants.collSubmissions).doc(submissionId).update({
      'grade': grade,
      'feedback': feedback,
    });
  }
}