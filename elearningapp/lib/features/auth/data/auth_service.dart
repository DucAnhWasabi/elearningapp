import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import 'user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Hàm đăng nhập chính
  Future<UserModel> signIn(String inputEmail, String password) async {
    String finalEmail = inputEmail.trim();
    String finalPassword = password;

    // Logic Admin cũ giữ nguyên
    if (inputEmail.trim() == 'admin' && password == 'admin') {
      finalEmail = 'admin@elearning.com';
      finalPassword = 'adminPassword123';
    }

    try {
      // 1. Đăng nhập Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: finalEmail,
        password: finalPassword,
      );

      String authUid = userCredential.user!.uid;

      // 2. CÁCH 1: Tìm theo ID (Ưu tiên)
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.collUsers)
          .doc(authUid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }

      // 3. CÁCH 2: (MỚI) Nếu không thấy ID, tìm theo Email
      // Đây là phao cứu sinh cho trường hợp Import CSV
      final queryByEmail = await _firestore
          .collection(AppConstants.collUsers)
          .where('email', isEqualTo: finalEmail)
          .limit(1)
          .get();

      if (queryByEmail.docs.isNotEmpty) {
        return UserModel.fromFirestore(queryByEmail.docs.first);
      }

      // 4. Nếu cả 2 đều không thấy
      throw Exception("User record not found in Database!");

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception("Tài khoản hoặc mật khẩu không đúng.");
      }
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Hàm kiểm tra danh sách email đã tồn tại chưa (Dùng cho CSV Import)
  Future<List<String>> checkExistingEmails(List<String> emails) async {
    if (emails.isEmpty) return [];

    // Firestore giới hạn 'whereIn' tối đa 10 phần tử, nên nếu list dài phải chia nhỏ
    // Ở đây làm demo đơn giản, thực tế cần thuật toán chia batch
    final List<String> existing = [];

    // Cách đơn giản: Lấy tất cả user về check (tạm chấp nhận với quy mô nhỏ)
    // Cách tối ưu: Dùng Cloud Function, nhưng ở đây ta dùng client-side cache
    QuerySnapshot snapshot = await _firestore.collection(AppConstants.collUsers).get();

    for (var doc in snapshot.docs) {
      String dbEmail = doc.get('email') as String;
      if (emails.contains(dbEmail)) {
        existing.add(dbEmail);
      }
    }
    return existing;
  }

  // Tạo user sinh viên vào Firestore (Batch write cho nhanh)
  Future<void> createStudentBatch(List<UserModel> students) async {
    WriteBatch batch = _firestore.batch();

    for (var student in students) {
      // Dùng email làm ID tạm thời hoặc UUID nếu muốn
      // Ở đây ta dùng UUID random cho ID document
      DocumentReference docRef = _firestore.collection(AppConstants.collUsers).doc();

      // Update ID vào model
      Map<String, dynamic> data = student.toMap();
      // Mặc định role STUDENT
      data['role'] = AppConstants.roleStudent;
      data['createdAt'] = FieldValue.serverTimestamp();

      batch.set(docRef, data);
    }

    await batch.commit();
  }
}