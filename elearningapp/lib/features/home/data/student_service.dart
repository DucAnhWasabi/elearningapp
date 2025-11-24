import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../course/data/course_model.dart';

class StudentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy danh sách khóa học mà sinh viên đang theo học
  Future<List<CourseModel>> getEnrolledCourses(String studentId) async {
    // 1. Lấy danh sách Enrollment của sinh viên này
    final enrollQuery = await _db.collection(AppConstants.collEnrollments)
        .where('userId', isEqualTo: studentId)
        .get();

    if (enrollQuery.docs.isEmpty) return [];

    // 2. Lấy ra list các CourseID
    final courseIds = enrollQuery.docs.map((doc) => doc['courseId'] as String).toList();

    // 3. Query bảng Courses để lấy thông tin chi tiết
    // Lưu ý: Firestore 'whereIn' giới hạn 10 phần tử. Nếu SV học > 10 môn cần chia batch.
    // Ở đây ta giả định SV học < 10 môn/kỳ.
    if (courseIds.isEmpty) return [];

    final courseQuery = await _db.collection(AppConstants.collCourses)
        .where(FieldPath.documentId, whereIn: courseIds)
        .get();

    return courseQuery.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
  }
}