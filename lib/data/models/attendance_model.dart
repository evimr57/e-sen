import 'package:esen/data/models/work_schedule_model.dart';

class AttendanceModel {
  final int? id;
  final int userId;
  final String userName;
  final String dateTime;
  final double latitude;
  final double longitude;
  final String photoPath;
  final double distance;
  final String status; // 'hadir' or 'di luar radius'

  AttendanceModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.dateTime,
    required this.latitude,
    required this.longitude,
    required this.photoPath,
    required this.distance,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'user_name': userName,
      'date_time': dateTime,
      'latitude': latitude,
      'longitude': longitude,
      'photo_path': photoPath,
      'distance': distance,
      'status': status,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      userName: map['user_name'] as String? ?? 'Karyawan',
      dateTime: map['date_time'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      photoPath: map['photo_path'] as String,
      distance: (map['distance'] as num).toDouble(),
      status: map['status'] as String,
    );
  }

  String getAttendanceType(List<AttendanceModel> allUserLogsForDay) {
    final sorted = List<AttendanceModel>.from(allUserLogsForDay)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (sorted.isEmpty) return 'Masuk';
    if (sorted.first.dateTime == dateTime) return 'Masuk';
    if (sorted.last.dateTime == dateTime && sorted.length > 1) return 'Pulang';
    return 'Absen Lainnya';
  }

  /// Determines punctuality status against a dynamic [schedule] for the day
  /// this attendance record falls on. If [schedule] is null or marked as a
  /// day off (isActive == false), falls back to a neutral 'Hadir' status
  /// since there's no defined start/end time to compare against.
  ///
  /// Returns one of: 'Luar Radius', 'Tepat Waktu', 'Terlambat',
  /// 'Pulang Normal', 'Pulang Cepat', 'Hadir'.
  String getPunctualityStatus(String type, WorkScheduleModel? schedule) {
    if (status != 'hadir') return 'Luar Radius';
    if (schedule == null || !schedule.isActive) return 'Hadir';

    try {
      final timeStr = dateTime.substring(11, 16); // "HH:mm"
      final actualMinutes = _toMinutes(timeStr);

      if (type == 'Masuk') {
        final scheduledMinutes = _toMinutes(schedule.startTime);
        return actualMinutes <= scheduledMinutes ? 'Tepat Waktu' : 'Terlambat';
      } else if (type == 'Pulang') {
        final scheduledMinutes = _toMinutes(schedule.endTime);
        return actualMinutes >= scheduledMinutes
            ? 'Pulang Normal'
            : 'Pulang Cepat';
      }
    } catch (_) {}
    return 'Hadir';
  }

  /// Calculates how many minutes late (positive) or early (negative) this
  /// attendance record is, relative to [schedule]. Returns null if not
  /// applicable (e.g. day off, no schedule, or status isn't 'hadir').
  int? getMinutesDifference(String type, WorkScheduleModel? schedule) {
    if (status != 'hadir') return null;
    if (schedule == null || !schedule.isActive) return null;

    try {
      final timeStr = dateTime.substring(11, 16);
      final actualMinutes = _toMinutes(timeStr);

      if (type == 'Masuk') {
        final scheduledMinutes = _toMinutes(schedule.startTime);
        return actualMinutes - scheduledMinutes; // positive = telat
      } else if (type == 'Pulang') {
        final scheduledMinutes = _toMinutes(schedule.endTime);
        return scheduledMinutes - actualMinutes; // positive = pulang cepat
      }
    } catch (_) {}
    return null;
  }

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }
}