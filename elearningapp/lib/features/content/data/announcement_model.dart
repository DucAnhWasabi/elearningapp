import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String courseId;
  final String authorName; // Tên giảng viên
  final String content;    // Nội dung thông báo
  final DateTime createdAt;
  final List<String> viewerIds; // Danh sách ID sinh viên đã xem

  AnnouncementModel({
    required this.id,
    required this.courseId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.viewerIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'authorName': authorName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'viewerIds': viewerIds,
    };
  }

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      authorName: data['authorName'] ?? 'Instructor',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      viewerIds: List<String>.from(data['viewerIds'] ?? []),
    );
  }
}