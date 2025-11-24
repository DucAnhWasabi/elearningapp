import 'package:sqflite/sqflite.dart';
import '../../features/semester/data/semester_model.dart';
import '../../features/course/data/course_model.dart';
import 'database_helper.dart';

class OfflineService {
  // --- SEMESTER ---
  Future<void> saveSemesters(List<SemesterModel> semesters) async {
    final db = await DatabaseHelper.instance.database;
    Batch batch = db.batch();

    // Xóa dữ liệu cũ để tránh trùng lặp/rác
    batch.delete('semesters');

    for (var sem in semesters) {
      batch.insert('semesters', {
        'id': sem.id,
        'name': sem.name,
        'startDate': sem.startDate.millisecondsSinceEpoch,
        'endDate': sem.endDate.millisecondsSinceEpoch,
        'isActive': sem.isActive ? 1 : 0, // SQLite không có boolean
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<SemesterModel>> getLocalSemesters() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('semesters', orderBy: 'startDate DESC');

    return result.map((json) => SemesterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] as int),
      isActive: (json['isActive'] as int) == 1,
    )).toList();
  }

  // --- COURSES ---
  Future<void> saveCourses(List<CourseModel> courses) async {
    final db = await DatabaseHelper.instance.database;
    Batch batch = db.batch();

    // Xóa cũ
    batch.delete('courses'); // Thực tế nên xóa theo semesterId nếu muốn cache từng phần

    for (var c in courses) {
      batch.insert('courses', {
        'id': c.id,
        'semesterId': c.semesterId,
        'code': c.code,
        'name': c.name,
        'subject': c.subject,
        'description': c.description,
        // 'teacherId': ... (nếu model có)
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<CourseModel>> getLocalCourses(String semesterId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
        'courses',
        where: 'semesterId = ?',
        whereArgs: [semesterId]
    );

    return result.map((json) => CourseModel(
      id: json['id'] as String,
      semesterId: json['semesterId'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
    )).toList();
  }
}