// lib/services/db_service.dart
// lib/services/db_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    // Use sqflite's own getDatabasesPath – simple and reliable
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'students.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE students(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            age INTEGER,
            grade TEXT,
            email TEXT,
            phone TEXT
          )
        ''');

        // Seed some initial data
        final initial = [
          ['Alice Johnson', 16, '10A', 'alice.j@example.com', '9876540001'],
          ['Bob Smith', 17, '11B', 'bob.smith@example.com', '9876540002'],
          ['Charlie Brown', 15, '9C', 'charlie.b@example.com', '9876540003'],
          ['David Lee', 16, '10B', 'david.lee@example.com', '9876540004'],
          ['Eva Green', 17, '11A', 'eva.green@example.com', '9876540005'],
          ['Fiona White', 16, '10C', 'fiona.white@example.com', '9876540006'],
          ['George King', 15, '9A', 'george.king@example.com', '9876540007'],
          ['Hannah Scott', 17, '11C', 'hannah.scott@example.com', '9876540008'],
          ['Ian Walker', 15, '9B', 'ian.walker@example.com', '9876540009'],
          ['Jackie Chan', 16, '10A', 'jackie.chan@example.com', '9876540010'],
        ];
        for (var s in initial) {
          await db.insert('students', {
            'name': s[0],
            'age': s[1],
            'grade': s[2],
            'email': s[3],
            'phone': s[4],
          });
        }
      },
    );
  }

  /// Insert and return the new row id
  Future<int> insertStudent(Student s) async {
    final db = await database;
    final id = await db.insert('students', s.toMap());
    return id;
  }

  Future<int> updateStudent(Student s) async {
    final db = await database;
    return await db.update(
      'students',
      s.toMap(),
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Student>> searchStudentsByName(String query) async {
    final db = await database;
    if (query.trim().isEmpty) return [];
    final rows = await db.rawQuery(
      "SELECT * FROM students WHERE name LIKE ? ORDER BY name LIMIT 20",
      ['%$query%'],
    );
    return rows.map((r) => Student.fromMap(r)).toList();
  }

  Future<Student?> getStudentById(int id) async {
    final db = await database;
    final rows = await db.query('students', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Student.fromMap(rows.first);
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final rows = await db.query('students', orderBy: 'name');
    return rows.map((r) => Student.fromMap(r)).toList();
  }
}
