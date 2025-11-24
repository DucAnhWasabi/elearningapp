import 'package:cloud_firestore/cloud_firestore.dart';

// --- COURSE MODEL ---
class CourseModel {
  final String id;
  final String semesterId;
  final String code; // Mã môn (INT3306)
  final String name; // Tên môn
  final String subject; // Chủ đề (IT only)
  final String description;

  CourseModel({
    required this.id,
    required this.semesterId,
    required this.code,
    required this.name,
    required this.subject,
    required this.description,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      semesterId: data['semesterId'] ?? '',
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'semesterId': semesterId,
      'code': code,
      'name': name,
      'subject': subject,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// --- GROUP MODEL ---
class GroupModel {
  final String id;
  final String courseId;
  final String name; // Tên nhóm (Nhóm 1 - Thứ 2)
  final int studentCount; // Cache số lượng SV

  GroupModel({
    required this.id,
    required this.courseId,
    required this.name,
    this.studentCount = 0,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      name: data['name'] ?? '',
      studentCount: data['studentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'name': name,
      'studentCount': studentCount,
    };
  }
}