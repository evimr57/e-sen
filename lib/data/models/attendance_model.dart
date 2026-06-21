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

  String getPunctualityStatus(String type) {
    if (status != 'hadir') return 'Luar Radius';
    
    try {
      final timeStr = dateTime.substring(11, 16); // "HH:mm"
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      if (type == 'Masuk') {
        if (hour < 8 || (hour == 8 && minute == 0)) {
          return 'Tepat Waktu';
        } else {
          return 'Terlambat';
        }
      } else if (type == 'Pulang') {
        if (hour >= 16) {
          return 'Pulang Normal';
        } else {
          return 'Pulang Cepat';
        }
      }
    } catch (_) {}
    return 'Hadir';
  }
}
