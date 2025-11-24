import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.localDbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Bảng Semesters (Học kỳ)
    await db.execute('''
      CREATE TABLE semesters (
        id TEXT PRIMARY KEY,
        name TEXT,
        startDate INTEGER,
        endDate INTEGER,
        isActive INTEGER
      )
    ''');

    // 2. Bảng Courses (Khóa học)
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        semesterId TEXT,
        code TEXT,
        name TEXT,
        subject TEXT,
        description TEXT,
        teacherId TEXT
      )
    ''');

    // Bạn có thể thêm bảng announcements, materials... sau này
  }
}