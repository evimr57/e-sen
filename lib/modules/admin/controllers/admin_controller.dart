import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:esen/core/database/db_helper.dart';
import 'package:esen/data/models/coordinate_model.dart';
import 'package:esen/data/models/attendance_model.dart';
import 'package:esen/data/models/user_model.dart';
import 'package:esen/data/models/work_schedule_model.dart';
import 'package:esen/core/theme/app_theme.dart';

class AdminController extends GetxController {
  // Input fields for coordinate settings
  final nameController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  final radiusController = TextEditingController();

  final rxIsLoading = false.obs;
  final rxNavIndex = 0.obs; // bottom navigation active tab

  // Reactive values for the map preview in coordinate management
  final rxFormLatitude = 0.0.obs;
  final rxFormLongitude = 0.0.obs;
  final rxFormRadius = 100.0.obs;

  // Real stats
  final rxTotalEmployees = 0.obs;
  final rxWeeklyTrend = <String, Map<String, dynamic>>{
    'Sen': {'percentage': 0.0, 'count': 0},
    'Sel': {'percentage': 0.0, 'count': 0},
    'Rab': {'percentage': 0.0, 'count': 0},
    'Kam': {'percentage': 0.0, 'count': 0},
    'Jum': {'percentage': 0.0, 'count': 0},
    'Sab': {'percentage': 0.0, 'count': 0},
    'Min': {'percentage': 0.0, 'count': 0},
  }.obs;

  // Data lists
  final rxCoordinates = <CoordinateModel>[].obs;
  final rxAttendanceLogs = <AttendanceModel>[].obs;

  // Stats
  final rxTotalAbsensi = 0.obs;
  final rxTotalHadir = 0.obs;
  final rxTotalLuarRadius = 0.obs;

  // Work schedule (7 days, Senin=1 ... Minggu=7)
  final rxWorkSchedules = <WorkScheduleModel>[].obs;

  @override
  void onInit() {
    super.onInit();

    // Add text field listeners to update reactive preview map values in real time
    latitudeController.addListener(() {
      final val = double.tryParse(latitudeController.text);
      if (val != null) rxFormLatitude.value = val;
    });
    longitudeController.addListener(() {
      final val = double.tryParse(longitudeController.text);
      if (val != null) rxFormLongitude.value = val;
    });
    radiusController.addListener(() {
      final val = double.tryParse(radiusController.text);
      if (val != null) rxFormRadius.value = val;
    });

    refreshData();
  }

  @override
  void onClose() {
    nameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    radiusController.dispose();
    super.onClose();
  }

  Future<void> refreshData() async {
    rxIsLoading.value = true;
    try {
      await loadCoordinates();
      await loadAttendanceLogs();
      await loadWorkSchedules();
      await calculateStats();
      await loadEmployees();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat data: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }

  Future<void> loadCoordinates() async {
    final coords = await DbHelper.instance.getCoordinates();
    rxCoordinates.assignAll(coords);
    if (coords.isNotEmpty) {
      // Prefill coordinate editor with the first coordinate (default primary)
      final primary = coords.first;
      nameController.text = primary.name;
      latitudeController.text = primary.latitude.toString();
      longitudeController.text = primary.longitude.toString();
      radiusController.text = primary.radiusMeters.toString();
      rxFormLatitude.value = primary.latitude;
      rxFormLongitude.value = primary.longitude;
      rxFormRadius.value = primary.radiusMeters;
    } else {
      nameController.text = 'Kantor Utama';
      latitudeController.text = '-6.175392';
      longitudeController.text = '106.827153';
      radiusController.text = '100.0';
      rxFormLatitude.value = -6.175392;
      rxFormLongitude.value = 106.827153;
      rxFormRadius.value = 100.0;
    }
  }

  Future<void> loadAttendanceLogs() async {
    final logs = await DbHelper.instance.getAttendanceLogs();
    rxAttendanceLogs.assignAll(logs);
  }

  Future<void> calculateStats() async {
    final todayStr = DateTime.now().toIso8601String().substring(
      0,
      10,
    ); // YYYY-MM-DD
    final todayLogs = rxAttendanceLogs
        .where((log) => log.dateTime.startsWith(todayStr))
        .toList();

    rxTotalAbsensi.value = todayLogs.length;
    rxTotalHadir.value = todayLogs.where((log) => log.status == 'hadir').length;
    rxTotalLuarRadius.value = todayLogs
        .where((log) => log.status != 'hadir')
        .length;

    // Get real total employee count from database
    final totalEmployees = await DbHelper.instance.getEmployeeCount();
    rxTotalEmployees.value = totalEmployees;

    // Calculate weekly attendance trend (Monday to Sunday of current week)
    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final Map<String, Map<String, dynamic>> trend = {};

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dayDateStr = dayDate.toIso8601String().substring(0, 10);

      // Count unique users who checked in on this day
      final dayLogs = rxAttendanceLogs
          .where((log) => log.dateTime.startsWith(dayDateStr))
          .toList();
      final uniqueUserIds = dayLogs.map((l) => l.userId).toSet();
      final count = uniqueUserIds.length;

      final pct = totalEmployees > 0 ? (count / totalEmployees) : 0.0;
      trend[dayNames[i]] = {'percentage': pct.clamp(0.0, 1.0), 'count': count};
    }
    rxWeeklyTrend.assignAll(trend);
  }

  // --- Coordinate Operations ---
  Future<void> saveCoordinate() async {
    final name = nameController.text.trim();
    final latStr = latitudeController.text.trim();
    final lngStr = longitudeController.text.trim();
    final radStr = radiusController.text.trim();

    if (name.isEmpty || latStr.isEmpty || lngStr.isEmpty || radStr.isEmpty) {
      Get.snackbar(
        'Error',
        'Semua kolom koordinat wajib diisi',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lngStr);
    final rad = double.tryParse(radStr);

    if (lat == null || lng == null || rad == null) {
      Get.snackbar(
        'Error',
        'Format koordinat atau radius harus angka desimal',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    rxIsLoading.value = true;
    try {
      if (rxCoordinates.isNotEmpty) {
        // Update existing primary coordinate
        final current = rxCoordinates.first;
        final updated = CoordinateModel(
          id: current.id,
          name: name,
          latitude: lat,
          longitude: lng,
          radiusMeters: rad,
        );
        await DbHelper.instance.updateCoordinate(updated);
        Get.snackbar(
          'Sukses',
          'Titik koordinat berhasil diperbarui',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
      } else {
        // Create new
        final newCoord = CoordinateModel(
          name: name,
          latitude: lat,
          longitude: lng,
          radiusMeters: rad,
        );
        await DbHelper.instance.setCoordinate(newCoord);
        Get.snackbar(
          'Sukses',
          'Titik koordinat berhasil disimpan',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
      }
      await refreshData();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyimpan koordinat: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }

  // --- Attendance Log CRUD ---
  Future<void> updateAttendanceStatus(
    AttendanceModel log,
    String newStatus,
  ) async {
    final updated = AttendanceModel(
      id: log.id,
      userId: log.userId,
      userName: log.userName,
      dateTime: log.dateTime,
      latitude: log.latitude,
      longitude: log.longitude,
      photoPath: log.photoPath,
      distance: log.distance,
      status: newStatus,
    );

    rxIsLoading.value = true;
    try {
      await DbHelper.instance.updateAttendance(updated);
      Get.snackbar(
        'Sukses',
        'Status absensi berhasil diubah',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await refreshData();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memperbarui status: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }

  Future<void> deleteAttendanceLog(int id) async {
    rxIsLoading.value = true;
    try {
      await DbHelper.instance.deleteAttendance(id);
      Get.snackbar(
        'Sukses',
        'Data absensi berhasil dihapus',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await refreshData();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus data: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }

  Future<void> fetchCurrentLocationForForm() async {
    rxIsLoading.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'GPS Nonaktif',
          'Harap aktifkan GPS Anda terlebih dahulu',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Izin Ditolak',
            'Aplikasi memerlukan izin akses lokasi',
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      latitudeController.text = position.latitude.toString();
      longitudeController.text = position.longitude.toString();
      Get.snackbar(
        'Sukses',
        'Lokasi GPS saat ini berhasil disematkan',
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengambil lokasi saat ini: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }

  // --- Employee CRUD ---
  final rxEmployees = <UserModel>[].obs;

  Future<void> loadEmployees() async {
    final employees = await DbHelper.instance.getAllEmployees();
    rxEmployees.assignAll(employees);
  }

  Future<void> addEmployee(
    String username,
    String email,
    String password,
  ) async {
    final isTaken = await DbHelper.instance.isUsernameTaken(username);
    if (isTaken) {
      Get.snackbar(
        'Gagal',
        'Username sudah terdaftar',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final newEmployee = UserModel(
      username: username,
      email: email,
      password: password,
      role: 'user',
    );

    rxIsLoading.value = true;
    try {
      await DbHelper.instance.registerUser(newEmployee);
      Get.snackbar(
        'Sukses',
        'Karyawan berhasil ditambahkan',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await refreshData();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menambahkan karyawan: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }

  Future<void> editEmployee(UserModel updatedEmployee) async {
    rxIsLoading.value = true;
    try {
      await DbHelper.instance.updateUser(updatedEmployee);
      Get.snackbar(
        'Sukses',
        'Data karyawan berhasil diperbarui',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await refreshData();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memperbarui data karyawan: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }

  Future<void> deleteEmployee(int id) async {
    rxIsLoading.value = true;
    try {
      await DbHelper.instance.deleteUser(id);
      Get.snackbar(
        'Sukses',
        'Karyawan berhasil dihapus',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await refreshData();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus karyawan: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }

  // --- Work Schedule Operations ---

  /// Loads all 7 day schedules from the database into [rxWorkSchedules].
  Future<void> loadWorkSchedules() async {
    final schedules = await DbHelper.instance.getWorkSchedules();
    rxWorkSchedules.assignAll(schedules);
  }

  /// Saves an updated schedule for a single day. [updated] must carry the
  /// same `id` as the existing row (use `copyWith` on the original model).
  Future<void> saveWorkSchedule(WorkScheduleModel updated) async {
    rxIsLoading.value = true;
    try {
      await DbHelper.instance.updateWorkSchedule(updated);
      Get.snackbar(
        'Sukses',
        'Jadwal ${updated.dayName} berhasil diperbarui',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
      await loadWorkSchedules();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memperbarui jadwal: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }

  /// Returns the schedule matching [date]'s day of week from the currently
  /// loaded [rxWorkSchedules], or null if not found (e.g. not loaded yet).
  /// Useful when computing punctuality for a specific attendance log.
  WorkScheduleModel? getScheduleForDate(DateTime date) {
    final dayOfWeek = date.weekday; // 1 = Senin ... 7 = Minggu
    try {
      return rxWorkSchedules.firstWhere((s) => s.dayOfWeek == dayOfWeek);
    } catch (_) {
      return null;
    }
  }

  /// Convenience overload: parses an ISO-ish dateTime string ("yyyy-MM-dd...")
  /// and returns the matching schedule.
  WorkScheduleModel? getScheduleForDateTimeString(String dateTimeStr) {
    try {
      final date = DateTime.parse(dateTimeStr);
      return getScheduleForDate(date);
    } catch (_) {
      return null;
    }
  }
}
