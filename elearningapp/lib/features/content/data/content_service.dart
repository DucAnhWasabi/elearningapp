import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import 'announcement_model.dart';

class ContentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Lấy danh sách Thông báo (Real-time)
  Stream<List<AnnouncementModel>> getAnnouncements(String courseId) {
    return _db.collection(AppConstants.collAnnouncements)
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AnnouncementModel.fromFirestore(d)).toList());
  }

  // 2. Đăng thông báo mới (Chỉ GV)
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    await _db.collection(AppConstants.collAnnouncements).add(announcement.toMap());
  }

  // 3. Tracking: Đánh dấu đã xem (Dành cho SV)
  Future<void> markAsViewed(String announcementId, String studentId) async {
    // Dùng arrayUnion để chỉ thêm ID nếu chưa tồn tại (tránh trùng)
    await _db.collection(AppConstants.collAnnouncements).doc(announcementId).update({
      'viewerIds': FieldValue.arrayUnion([studentId])
    });
  }
}