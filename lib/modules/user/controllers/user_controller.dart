import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:esen/core/database/db_helper.dart';
import 'package:esen/modules/auth/controllers/auth_controller.dart';
import 'package:esen/data/models/coordinate_model.dart';
import 'package:esen/data/models/attendance_model.dart';
import 'package:esen/core/theme/app_theme.dart';

class UserController extends GetxController {
  final rxIsLoading = false.obs;

  // Location States
  final rxCurrentPosition = Rxn<Position>();
  final rxTargetCoordinate = Rxn<CoordinateModel>();
  final rxDistance = 0.0.obs;
  final rxIsWithinRadius = false.obs;

  // Personal Attendance History
  final rxAttendanceHistory = <AttendanceModel>[].obs;

  // Selected Bottom Navigation Index
  final rxNavIndex = 0.obs;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    initLocationTracking();
    loadHistory();
  }

  Future<void> initLocationTracking() async {
    rxIsLoading.value = true;
    try {
      // 1. Load target coordinates set by admin
      final target = await DbHelper.instance.getPrimaryCoordinate();
      rxTargetCoordinate.value = target;

      // 2. Request and track location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'GPS Mati',
          'Harap aktifkan GPS perangkat Anda',
          backgroundColor: Colors.amber,
          colorText: Colors.black,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Izin Ditolak',
            'Akses lokasi diperlukan untuk absensi',
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Izin Ditolak Permanen',
          'Harap aktifkan izin lokasi di pengaturan sistem',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      // Get initial position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      rxCurrentPosition.value = position;

      // Calculate initial distance
      calculateDistanceAndRadius();

      // Listen to location updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // update every 5 meters
        ),
      ).listen((Position position) {
        rxCurrentPosition.value = position;
        calculateDistanceAndRadius();
      });
    } catch (e) {
      Get.snackbar(
        'GPS Error',
        'Gagal memuat GPS: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }

  void calculateDistanceAndRadius() {
    final pos = rxCurrentPosition.value;
    final target = rxTargetCoordinate.value;

    if (pos != null && target != null) {
      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        target.latitude,
        target.longitude,
      );
      rxDistance.value = dist;
      rxIsWithinRadius.value = dist <= target.radiusMeters;
    } else {
      rxDistance.value = 99999.0;
      rxIsWithinRadius.value = false;
    }
  }

  Future<void> loadHistory() async {
    final authController = Get.find<AuthController>();
    final user = authController.currentUser;
    if (user != null && user.id != null) {
      final history = await DbHelper.instance.getAttendanceByUserId(user.id!);
      rxAttendanceHistory.assignAll(history);
    }
  }

  Future<void> doAttendance() async {
    final authController = Get.find<AuthController>();
    final user = authController.currentUser;

    if (user == null || user.id == null) {
      Get.snackbar(
        'Sesi Berakhir',
        'Silakan login kembali',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (rxTargetCoordinate.value == null) {
      Get.snackbar(
        'Error',
        'Koordinat target absensi belum diatur oleh admin',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // Strict radius validation
    if (!rxIsWithinRadius.value) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
              SizedBox(width: 8),
              Text('Di Luar Radius'),
            ],
          ),
          content: Text(
            'Anda saat ini berjarak ${rxDistance.value.toStringAsFixed(1)}m dari kantor.\n\nSesuai aturan kantor, Anda wajib berada dalam radius maksimal ${rxTargetCoordinate.value!.radiusMeters.toStringAsFixed(0)}m untuk melakukan absensi.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    // Take photo
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
      );

      if (image == null) {
        Get.snackbar(
          'Dibatalkan',
          'Foto wajib diambil untuk absensi',
          backgroundColor: Colors.amber,
          colorText: Colors.black,
        );
        return;
      }

      rxIsLoading.value = true;

      // Save photo to App Documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'att_${user.username}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String localPath = p.join(appDocDir.path, fileName);
      final File savedImage = await File(image.path).copy(localPath);

      final attendance = AttendanceModel(
        userId: user.id!,
        userName: user.username,
        dateTime: DateTime.now()
            .toIso8601String()
            .replaceAll('T', ' ')
            .substring(0, 19),
        latitude: rxCurrentPosition.value!.latitude,
        longitude: rxCurrentPosition.value!.longitude,
        photoPath: savedImage.path,
        distance: rxDistance.value,
        status: 'hadir',
      );

      await DbHelper.instance.insertAttendance(attendance);

      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.success,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Absensi Berhasil',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Terima kasih! Absensi kehadiran Anda telah tercatat ke dalam sistem perkantoran.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      loadHistory();
                    },
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Gagal Absensi',
        'Gagal memproses absensi: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }
}
