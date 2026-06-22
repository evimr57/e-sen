import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:esen/modules/admin/controllers/admin_controller.dart';
import 'package:esen/core/theme/app_theme.dart';

class ManageAttendanceView extends GetView<AdminController> {
  const ManageAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    // Local state for search filtering
    final searchRx = ''.obs;
    final filterStatusRx = 'all'.obs; // 'all', 'hadir', 'luar_radius'

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Kelola Riwayat Absensi Karyawan'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 1. Premium Search & Filter Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                bottom: BorderSide(color: AppTheme.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => searchRx.value = val.toLowerCase(),
                  decoration: InputDecoration(
                    hintText: 'Cari nama karyawan...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    fillColor: AppTheme.background,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filtering Row
                Row(
                  children: [
                    _buildFilterTab(
                      label: 'Semua Absensi',
                      value: 'all',
                      current: filterStatusRx,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterTab(
                      label: 'Hadir',
                      value: 'hadir',
                      current: filterStatusRx,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterTab(
                      label: 'Luar Radius',
                      value: 'luar_radius',
                      current: filterStatusRx,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider shadow
          Container(height: 1, color: const Color(0xFFF1F5F9)),

          // 2. Attendance Data Table List
          Expanded(
            child: Obx(() {
              var logs = controller.rxAttendanceLogs;

              // Apply Search filter
              if (searchRx.value.isNotEmpty) {
                logs = logs
                    .where(
                      (log) =>
                          log.userName.toLowerCase().contains(searchRx.value),
                    )
                    .toList()
                    .obs;
              }

              // Apply Status filter
              if (filterStatusRx.value == 'hadir') {
                logs = logs.where((log) => log.status == 'hadir').toList().obs;
              } else if (filterStatusRx.value == 'luar_radius') {
                logs = logs.where((log) => log.status != 'hadir').toList().obs;
              }

              if (controller.rxIsLoading.value && logs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tidak ada entri log absensi',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final isHadir = log.status == 'hadir';
                  final userLogsForDay = controller.rxAttendanceLogs
                      .where(
                        (l) =>
                            l.userId == log.userId &&
                            l.dateTime.startsWith(
                              log.dateTime.substring(0, 10),
                            ),
                      )
                      .toList();
                  final type = log.getAttendanceType(userLogsForDay);
                  final schedule = controller.getScheduleForDateTimeString(
                    log.dateTime,
                  );
                  final punctuality = log.getPunctualityStatus(type, schedule);
                  final minutesDiff = log.getMinutesDifference(type, schedule);

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppTheme.cardShadow,
                      border: Border.all(color: AppTheme.border, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row Header: Avatar, Name, and Dropdown Actions
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  _showPhotoDialog(context, log.photoPath),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.border,
                                    width: 1.5,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: File(log.photoPath).existsSync()
                                      ? Image.file(
                                          File(log.photoPath),
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.broken_image_rounded,
                                          color: Colors.grey,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    log.dateTime,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // PopUp Control Menu Button
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppTheme.textSecondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (action) {
                                if (action == 'toggle') {
                                  final newStatus = isHadir
                                      ? 'di luar radius'
                                      : 'hadir';
                                  controller.updateAttendanceStatus(
                                    log,
                                    newStatus,
                                  );
                                } else if (action == 'delete') {
                                  _showDeleteConfirm(context, log.id!);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isHadir
                                            ? Icons.cancel_outlined
                                            : Icons
                                                  .check_circle_outline_rounded,
                                        color: isHadir
                                            ? AppTheme.warning
                                            : AppTheme.success,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isHadir
                                            ? 'Pindahkan Luar Radius'
                                            : 'Koreksi ke Hadir',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppTheme.danger,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Hapus Log Absen',
                                        style: TextStyle(
                                          color: AppTheme.danger,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Divider(height: 24, color: Color(0xFFF1F5F9)),

                        // Row Details: GPS location parameters & indicators
                        Row(
                          children: [
                            Expanded(
                              child: _buildLogMeta(
                                Icons.radar,
                                'Jarak target: ${log.distance.toStringAsFixed(1)}m',
                              ),
                            ),
                            Expanded(
                              child: _buildLogMeta(
                                Icons.location_on_outlined,
                                'Lat: ${log.latitude.toStringAsFixed(5)}',
                              ),
                            ),
                            Expanded(
                              child: _buildLogMeta(
                                Icons.explore_outlined,
                                'Lng: ${log.longitude.toStringAsFixed(5)}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Bottom Layout: Badge indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Verifikasi Absensi:',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              alignment: WrapAlignment.end,
                              children: [
                                // 1. Type Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: type == 'Masuk'
                                        ? const Color(
                                            0xFF3B82F6,
                                          ).withValues(alpha: 0.12)
                                        : type == 'Pulang'
                                        ? const Color(
                                            0xFFFF6B00,
                                          ).withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    type.toUpperCase(),
                                    style: TextStyle(
                                      color: type == 'Masuk'
                                          ? const Color(0xFF3B82F6)
                                          : type == 'Pulang'
                                          ? const Color(0xFFFF6B00)
                                          : Colors.grey,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // 2. Punctuality/Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (punctuality == 'Tepat Waktu' ||
                                            punctuality == 'Pulang Normal')
                                        ? AppTheme.success.withValues(
                                            alpha: 0.12,
                                          )
                                        : (punctuality == 'Terlambat' ||
                                              punctuality == 'Pulang Cepat')
                                        ? AppTheme.warning.withValues(
                                            alpha: 0.12,
                                          )
                                        : AppTheme.danger.withValues(
                                            alpha: 0.12,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (punctuality == 'Tepat Waktu' ||
                                                punctuality == 'Pulang Normal')
                                            ? Icons.check_circle_rounded
                                            : (punctuality == 'Terlambat' ||
                                                  punctuality == 'Pulang Cepat')
                                            ? Icons.warning_amber_rounded
                                            : Icons.cancel_outlined,
                                        color:
                                            (punctuality == 'Tepat Waktu' ||
                                                punctuality == 'Pulang Normal')
                                            ? AppTheme.success
                                            : (punctuality == 'Terlambat' ||
                                                  punctuality == 'Pulang Cepat')
                                            ? AppTheme.warning
                                            : AppTheme.danger,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        minutesDiff != null &&
                                                minutesDiff != 0 &&
                                                (punctuality == 'Terlambat' ||
                                                    punctuality ==
                                                        'Pulang Cepat')
                                            ? '${punctuality.toUpperCase()} ${minutesDiff.abs()} MENIT'
                                            : punctuality.toUpperCase(),
                                        style: TextStyle(
                                          color:
                                              (punctuality == 'Tepat Waktu' ||
                                                  punctuality ==
                                                      'Pulang Normal')
                                              ? AppTheme.success
                                              : (punctuality == 'Terlambat' ||
                                                    punctuality ==
                                                        'Pulang Cepat')
                                              ? AppTheme.warning
                                              : AppTheme.danger,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLogMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab({
    required String label,
    required String value,
    required RxString current,
  }) {
    return Obx(() {
      final isSel = current.value == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => current.value = value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSel ? AppTheme.primary : AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSel ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showDeleteConfirm(BuildContext context, int id) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Log Absensi'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus data absensi ini secara permanen? Langkah ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteAttendanceLog(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text(
              'Hapus Permanen',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, String path) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppTheme.surface,
              ),
              child: File(path).existsSync()
                  ? Image.file(File(path), fit: BoxFit.contain)
                  : const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black45,
                child: Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }
}
