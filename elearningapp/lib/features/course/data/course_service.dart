import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import 'course_model.dart';

class CourseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- COURSE METHODS ---

  // Lấy danh sách khóa học theo Học kỳ
  Stream<List<CourseModel>> getCoursesBySemester(String semesterId) {
    return _db.collection(AppConstants.collCourses)
        .where('semesterId', isEqualTo: semesterId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CourseModel.fromFirestore(d)).toList());
  }

  Future<void> addCourse(CourseModel course) async {
    await _db.collection(AppConstants.collCourses).add(course.toMap());
  }

  Future<void> deleteCourse(String courseId) async {
    // Cảnh báo: Thực tế nên xóa cả Groups và Enrollments con của nó (Cloud Function tốt hơn)
    await _db.collection(AppConstants.collCourses).doc(courseId).delete();
  }

  // --- GROUP METHODS ---

  // Lấy danh sách nhóm trong 1 khóa học
  Stream<List<GroupModel>> getGroupsByCourse(String courseId) {
    return _db.collection(AppConstants.collGroups)
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => GroupModel.fromFirestore(d)).toList());
  }

  Future<void> addGroup(GroupModel group) async {
    await _db.collection(AppConstants.collGroups).add(group.toMap());
  }

  Future<void> deleteGroup(String groupId) async {
    await _db.collection(AppConstants.collGroups).doc(groupId).delete();
  }
}