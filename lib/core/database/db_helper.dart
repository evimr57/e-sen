import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:checkly/data/models/user_model.dart';
import 'package:checkly/data/models/coordinate_model.dart';
import 'package:checkly/data/models/attendance_model.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('checkly.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        // Ensure all tables are created robustly using IF NOT EXISTS
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            photo_profile TEXT
          )
        ''');

        // Migration: add photo_profile column to users if not exists
        try {
          await db.execute("ALTER TABLE users ADD COLUMN photo_profile TEXT");
        } catch (_) {
          // column already exists, ignore error
        }

        await db.execute('''
          CREATE TABLE IF NOT EXISTS coordinates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            radius_meters REAL NOT NULL DEFAULT 100.0
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            user_name TEXT NOT NULL,
            date_time TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            photo_path TEXT NOT NULL,
            distance REAL NOT NULL,
            status TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        // Seed admin if not present
        final adminCheck = await db.query('users', where: 'username = ?', whereArgs: ['admin']);
        if (adminCheck.isEmpty) {
          await db.insert('users', {
            'username': 'admin',
            'email': 'admin@office.com',
            'password': 'admin',
            'role': 'admin',
          });
        }

        // Seed default user if not present
        final userCheck = await db.query('users', where: 'username = ?', whereArgs: ['user']);
        if (userCheck.isEmpty) {
          await db.insert('users', {
            'username': 'user',
            'email': 'user@gmail.com',
            'password': 'user',
            'role': 'user',
          });
        } else {
          // Migration: update default employee email to @gmail.com if it's still @office.com
          await db.update(
            'users',
            {'email': 'user@gmail.com'},
            where: 'username = ? AND email = ?',
            whereArgs: ['user', 'user@office.com'],
          );
        }

        // Seed coordinates if empty
        final coordCheck = await db.query('coordinates');
        if (coordCheck.isEmpty) {
          await db.insert('coordinates', {
            'name': 'Kantor Pusat Monas',
            'latitude': -6.175392,
            'longitude': 106.827153,
            'radius_meters': 100.0,
          });
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Create users table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        photo_profile TEXT
      )
    ''');

    // 2. Create coordinates table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS coordinates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_meters REAL NOT NULL DEFAULT 100.0
      )
    ''');

    // 3. Create attendance table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        date_time TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        photo_path TEXT NOT NULL,
        distance REAL NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Seed default Admin & User
    final adminCheck = await db.query('users', where: 'username = ?', whereArgs: ['admin']);
    if (adminCheck.isEmpty) {
      await db.insert('users', {
        'username': 'admin',
        'email': 'admin@office.com',
        'password': 'admin', // Simple password for testing
        'role': 'admin',
      });
    }

    final userCheck = await db.query('users', where: 'username = ?', whereArgs: ['user']);
    if (userCheck.isEmpty) {
      await db.insert('users', {
        'username': 'user',
        'email': 'user@gmail.com',
        'password': 'user', // Simple password for testing
        'role': 'user',
      });
    }

    // Seed default location (e.g. Monas, Jakarta: -6.175392, 106.827153)
    final coordCheck = await db.query('coordinates');
    if (coordCheck.isEmpty) {
      await db.insert('coordinates', {
        'name': 'Kantor Pusat Monas',
        'latitude': -6.175392,
        'longitude': 106.827153,
        'radius_meters': 100.0,
      });
    }
  }

  // --- USER OPERATIONS ---

  Future<int> registerUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<int> updateUser(UserModel user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<UserModel?> loginUser(String identifier, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND password = ?',
      whereArgs: [identifier, identifier, password],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> isUsernameTaken(String username) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return maps.isNotEmpty;
  }

  Future<int> getEmployeeCount() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM users WHERE role = 'user'")
    );
    return count ?? 0;
  }

  Future<List<UserModel>> getAllEmployees() async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['user'],
      orderBy: 'id DESC',
    );
    return maps.map((e) => UserModel.fromMap(e)).toList();
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- COORDINATE OPERATIONS ---

  Future<int> setCoordinate(CoordinateModel coord) async {
    final db = await instance.database;
    return await db.insert('coordinates', coord.toMap());
  }

  Future<List<CoordinateModel>> getCoordinates() async {
    final db = await instance.database;
    final maps = await db.query('coordinates');
    return maps.map((e) => CoordinateModel.fromMap(e)).toList();
  }

  Future<CoordinateModel?> getPrimaryCoordinate() async {
    final db = await instance.database;
    final maps = await db.query('coordinates', limit: 1);
    if (maps.isNotEmpty) {
      return CoordinateModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCoordinate(CoordinateModel coord) async {
    final db = await instance.database;
    return await db.update(
      'coordinates',
      coord.toMap(),
      where: 'id = ?',
      whereArgs: [coord.id],
    );
  }

  Future<int> deleteCoordinate(int id) async {
    final db = await instance.database;
    return await db.delete(
      'coordinates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- ATTENDANCE OPERATIONS ---

  Future<int> insertAttendance(AttendanceModel attendance) async {
    final db = await instance.database;
    return await db.insert('attendance', attendance.toMap());
  }

  Future<List<AttendanceModel>> getAttendanceLogs() async {
    final db = await instance.database;
    final maps = await db.query('attendance', orderBy: 'date_time DESC');
    return maps.map((e) => AttendanceModel.fromMap(e)).toList();
  }

  Future<List<AttendanceModel>> getAttendanceByUserId(int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'attendance',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date_time DESC',
    );
    return maps.map((e) => AttendanceModel.fromMap(e)).toList();
  }

  Future<int> updateAttendance(AttendanceModel att) async {
    final db = await instance.database;
    return await db.update(
      'attendance',
      att.toMap(),
      where: 'id = ?',
      whereArgs: [att.id],
    );
  }

  Future<int> deleteAttendance(int id) async {
    final db = await instance.database;
    return await db.delete(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
