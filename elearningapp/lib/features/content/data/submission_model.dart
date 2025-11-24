import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName; // Cache tên để hiển thị cho nhanh
  final String fileUrl;     // Link file trên Storage
  final String fileName;
  final DateTime submittedAt;
  final double? grade;      // Điểm số (null = chưa chấm)
  final String? feedback;   // Nhận xét của GV

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.fileUrl,
    required this.fileName,
    required this.submittedAt,
    this.grade,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'grade': grade,
      'feedback': feedback,
    };
  }

  // Trạng thái nộp bài
  String get status {
    if (grade != null) return "Đã chấm điểm: $grade";
    return "Đã nộp bài";
  }

  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SubmissionModel(
      id: doc.id,
      assignmentId: data['assignmentId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Student',
      fileUrl: data['fileUrl'] ?? '',
      fileName: data['fileName'] ?? '',
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      grade: data['grade'] != null ? (data['grade'] as num).toDouble() : null,
      feedback: data['feedback'],
    );
  }
}