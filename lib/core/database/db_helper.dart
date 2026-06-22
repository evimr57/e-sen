import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:esen/data/models/user_model.dart';
import 'package:esen/data/models/coordinate_model.dart';
import 'package:esen/data/models/attendance_model.dart';
import 'package:esen/data/models/work_schedule_model.dart';

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

        // Work schedule table: one row per day of week (1=Senin ... 7=Minggu)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS work_schedule (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            day_of_week INTEGER NOT NULL UNIQUE,
            is_active INTEGER NOT NULL DEFAULT 1,
            start_time TEXT NOT NULL DEFAULT '08:00',
            end_time TEXT NOT NULL DEFAULT '16:00',
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            radius_meters REAL NOT NULL DEFAULT 100.0,
            location_name TEXT NOT NULL DEFAULT 'Lokasi Kerja'
          )
        ''');

        // Seed admin if not present
        final adminCheck = await db.query(
          'users',
          where: 'username = ?',
          whereArgs: ['admin'],
        );
        if (adminCheck.isEmpty) {
          await db.insert('users', {
            'username': 'admin',
            'email': 'admin@office.com',
            'password': 'admin',
            'role': 'admin',
          });
        }

        // Seed default user if not present
        final userCheck = await db.query(
          'users',
          where: 'username = ?',
          whereArgs: ['user'],
        );
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

        // Seed work_schedule if empty, using the primary coordinate as default location
        final scheduleCheck = await db.query('work_schedule');
        if (scheduleCheck.isEmpty) {
          final coords = await db.query('coordinates', limit: 1);
          final lat = coords.isNotEmpty
              ? (coords.first['latitude'] as num).toDouble()
              : -6.175392;
          final lng = coords.isNotEmpty
              ? (coords.first['longitude'] as num).toDouble()
              : 106.827153;
          final rad = coords.isNotEmpty
              ? (coords.first['radius_meters'] as num).toDouble()
              : 100.0;
          final locName = coords.isNotEmpty
              ? coords.first['name'] as String
              : 'Kantor Utama';

          final defaults = WorkScheduleModel.defaultSchedules(
            latitude: lat,
            longitude: lng,
            radiusMeters: rad,
            locationName: locName,
          );
          for (final schedule in defaults) {
            await db.insert('work_schedule', schedule.toMap());
          }
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

    // 4. Create work_schedule table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS work_schedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_of_week INTEGER NOT NULL UNIQUE,
        is_active INTEGER NOT NULL DEFAULT 1,
        start_time TEXT NOT NULL DEFAULT '08:00',
        end_time TEXT NOT NULL DEFAULT '16:00',
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_meters REAL NOT NULL DEFAULT 100.0,
        location_name TEXT NOT NULL DEFAULT 'Lokasi Kerja'
      )
    ''');

    // Seed default Admin & User
    final adminCheck = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
    );
    if (adminCheck.isEmpty) {
      await db.insert('users', {
        'username': 'admin',
        'email': 'admin@office.com',
        'password': 'admin', // Simple password for testing
        'role': 'admin',
      });
    }

    final userCheck = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['user'],
    );
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

    // Seed default work_schedule (Mon-Fri 08:00-16:00, Sat-Sun off)
    final scheduleCheck = await db.query('work_schedule');
    if (scheduleCheck.isEmpty) {
      final defaults = WorkScheduleModel.defaultSchedules(
        latitude: -6.175392,
        longitude: 106.827153,
        radiusMeters: 100.0,
        locationName: 'Kantor Pusat Monas',
      );
      for (final schedule in defaults) {
        await db.insert('work_schedule', schedule.toMap());
      }
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
      await db.rawQuery("SELECT COUNT(*) FROM users WHERE role = 'user'"),
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
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
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
    return await db.delete('coordinates', where: 'id = ?', whereArgs: [id]);
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
    return await db.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }

  // --- WORK SCHEDULE OPERATIONS ---

  /// Returns all 7 work schedule rows, ordered Senin (1) to Minggu (7).
  Future<List<WorkScheduleModel>> getWorkSchedules() async {
    final db = await instance.database;
    final maps = await db.query('work_schedule', orderBy: 'day_of_week ASC');
    return maps.map((e) => WorkScheduleModel.fromMap(e)).toList();
  }

  /// Returns the schedule for a specific day (1=Senin ... 7=Minggu), or null
  /// if somehow not seeded yet.
  Future<WorkScheduleModel?> getScheduleForDay(int dayOfWeek) async {
    final db = await instance.database;
    final maps = await db.query(
      'work_schedule',
      where: 'day_of_week = ?',
      whereArgs: [dayOfWeek],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return WorkScheduleModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateWorkSchedule(WorkScheduleModel schedule) async {
    final db = await instance.database;
    return await db.update(
      'work_schedule',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }
}