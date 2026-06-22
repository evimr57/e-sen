/// Represents the work schedule configuration for a single day of the week.
/// dayOfWeek follows DateTime.weekday convention: 1 = Monday ... 7 = Sunday.
class WorkScheduleModel {
  final int? id;
  final int dayOfWeek; // 1 (Senin) - 7 (Minggu)
  final bool isActive; // false = hari libur, tidak ada absensi diharapkan
  final String startTime; // format "HH:mm", contoh "08:00"
  final String endTime; // format "HH:mm", contoh "16:00"
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String locationName;

  WorkScheduleModel({
    this.id,
    required this.dayOfWeek,
    required this.isActive,
    required this.startTime,
    required this.endTime,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.locationName,
  });

  static const dayNames = {
    1: 'Senin',
    2: 'Selasa',
    3: 'Rabu',
    4: 'Kamis',
    5: 'Jumat',
    6: 'Sabtu',
    7: 'Minggu',
  };

  String get dayName => dayNames[dayOfWeek] ?? '-';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'day_of_week': dayOfWeek,
      'is_active': isActive ? 1 : 0,
      'start_time': startTime,
      'end_time': endTime,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'location_name': locationName,
    };
  }

  factory WorkScheduleModel.fromMap(Map<String, dynamic> map) {
    return WorkScheduleModel(
      id: map['id'] as int?,
      dayOfWeek: map['day_of_week'] as int,
      isActive: (map['is_active'] as int) == 1,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusMeters: (map['radius_meters'] as num).toDouble(),
      locationName: map['location_name'] as String? ?? 'Lokasi Kerja',
    );
  }

  WorkScheduleModel copyWith({
    bool? isActive,
    String? startTime,
    String? endTime,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? locationName,
  }) {
    return WorkScheduleModel(
      id: id,
      dayOfWeek: dayOfWeek,
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      locationName: locationName ?? this.locationName,
    );
  }

  /// Returns the default Mon-Fri 08:00-16:00 / Sat-Sun off schedule,
  /// used to seed the database on first run.
  static List<WorkScheduleModel> defaultSchedules({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String locationName,
  }) {
    return List.generate(7, (index) {
      final day = index + 1; // 1..7
      final isWeekend = day == 6 || day == 7;
      return WorkScheduleModel(
        dayOfWeek: day,
        isActive: !isWeekend,
        startTime: '08:00',
        endTime: '16:00',
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        locationName: locationName,
      );
    });
  }
}