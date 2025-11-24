import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/user_model.dart';
import 'enrollment_model.dart';

class EnrollmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Lấy danh sách sinh viên trong 1 nhóm
  // (Lấy Enrollment trước -> Lấy User Info sau)
  Stream<List<UserModel>> getStudentsInGroup(String groupId) {
    return _db.collection(AppConstants.collEnrollments)
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<UserModel> students = [];
      for (var doc in snapshot.docs) {
        String userId = doc['userId'];
        // Fetch user info
        var userDoc = await _db.collection(AppConstants.collUsers).doc(userId).get();
        if (userDoc.exists) {
          students.add(UserModel.fromFirestore(userDoc));
        }
      }
      return students;
    });
  }

  // 2. Thêm sinh viên vào nhóm (Có check trùng)
  Future<void> enrollStudent(String courseId, String groupId, String userId) async {
    // Bước A: Check xem sinh viên đã ở trong nhóm nào của môn này chưa
    final existingQuery = await _db.collection(AppConstants.collEnrollments)
        .where('courseId', isEqualTo: courseId)
        .where('userId', isEqualTo: userId)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      throw Exception("Sinh viên này đã thuộc một nhóm khác trong môn học này rồi!");
    }

    // Bước B: Nếu chưa, dùng Transaction để thêm Enrollment và Update Count
    await _db.runTransaction((transaction) async {
      // Tạo Enrollment
      final enrollRef = _db.collection(AppConstants.collEnrollments).doc();
      transaction.set(enrollRef, {
        'userId': userId,
        'courseId': courseId,
        'groupId': groupId,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Tăng biến đếm trong Group
      final groupRef = _db.collection(AppConstants.collGroups).doc(groupId);
      transaction.update(groupRef, {
        'studentCount': FieldValue.increment(1)
      });
    });
  }

  // 3. Xóa sinh viên khỏi nhóm
  Future<void> removeStudent(String groupId, String userId) async {
    // Tìm doc enrollment để xóa
    final query = await _db.collection(AppConstants.collEnrollments)
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .get();

    if (query.docs.isEmpty) return;

    await _db.runTransaction((transaction) async {
      // Xóa enrollment
      transaction.delete(query.docs.first.reference);

      // Giảm biến đếm
      final groupRef = _db.collection(AppConstants.collGroups).doc(groupId);
      transaction.update(groupRef, {
        'studentCount': FieldValue.increment(-1)
      });
    });
  }

  // 4. Tìm kiếm sinh viên để thêm (Loại trừ những người đã trong nhóm)
  Future<List<UserModel>> searchStudentsToAdd(String query) async {
    // Thực tế nên dùng Algolia/ElasticSearch, nhưng ở đây ta query simple
    // Lấy 20 sinh viên phù hợp
    final snapshot = await _db.collection(AppConstants.collUsers)
        .where('role', isEqualTo: AppConstants.roleStudent)
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThan: '${query}z')
        .limit(20)
        .get();

    return snapshot.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }
}