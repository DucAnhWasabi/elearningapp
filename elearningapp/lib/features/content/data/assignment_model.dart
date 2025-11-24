import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String courseId;
  final String title;
  final String instructions;
  final DateTime dueDate;     // Hạn chót
  final bool allowLate;       // Cho phép nộp trễ?
  final List<String> allowedFileTypes; // vd: ['pdf', 'zip']

  AssignmentModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.instructions,
    required this.dueDate,
    this.allowLate = false,
    this.allowedFileTypes = const ['pdf', 'zip'],
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'instructions': instructions,
      'dueDate': Timestamp.fromDate(dueDate),
      'allowLate': allowLate,
      'allowedFileTypes': allowedFileTypes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory AssignmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AssignmentModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      instructions: data['instructions'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      allowLate: data['allowLate'] ?? false,
      allowedFileTypes: List<String>.from(data['allowedFileTypes'] ?? ['pdf']),
    );
  }
}