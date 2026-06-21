import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:esen/modules/admin/controllers/admin_controller.dart';
import 'package:esen/modules/auth/controllers/auth_controller.dart';
import 'package:esen/modules/admin/views/manage_coordinate_view.dart';
import 'package:esen/modules/admin/views/manage_attendance_view.dart';
import 'package:esen/modules/admin/views/manage_employee_view.dart';
import 'package:esen/core/theme/app_theme.dart';

class AdminDashboardView extends GetView<AdminController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Obx(() {
        return IndexedStack(
          index: controller.rxNavIndex.value,
          children: [
            _buildDashboardTab(context, authController),
            const ManageCoordinateView(),
            const ManageAttendanceView(),
            const ManageEmployeeView(),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: controller.rxNavIndex.value,
            onDestinationSelected: (index) {
              controller.rxNavIndex.value = index;
            },
            backgroundColor: AppTheme.surface,
            indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
            height: 72,
            destinations: const [
              NavigationDestination(
                icon: Icon(
                  Icons.dashboard_outlined,
                  color: AppTheme.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.dashboard_rounded,
                  color: AppTheme.primary,
                ),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.pin_drop_outlined,
                  color: AppTheme.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.pin_drop_rounded,
                  color: AppTheme.primary,
                ),
                label: 'Koordinat',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.assignment_outlined,
                  color: AppTheme.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.assignment_rounded,
                  color: AppTheme.primary,
                ),
                label: 'Absensi',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.people_alt_outlined,
                  color: AppTheme.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.people_alt_rounded,
                  color: AppTheme.primary,
                ),
                label: 'Karyawan',
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDashboardTab(
    BuildContext context,
    AuthController authController,
  ) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard HRD'),
        automaticallyImplyLeading: false, // removes back arrow
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: authController.logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Welcome Header Card =====
              _buildWelcomeCard(context, authController),
              const SizedBox(height: 28),

              // ===== KPI Section (grouped under one section header) =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Indikator Utama Kehadiran (KPI)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hari Ini',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Obx(() {
                final totalLogs = controller.rxTotalAbsensi.value;
                final totalHadir = controller.rxTotalHadir.value;
                final totalLuarRadius = controller.rxTotalLuarRadius.value;

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildKpiCard(
                      title: 'Total Absensi',
                      value: '$totalLogs',
                      subtitle: 'Entri masuk hari ini',
                      icon: Icons.assignment_ind_outlined,
                      iconColor: AppTheme.primary,
                    ),
                    _buildKpiCard(
                      title: 'Hadir Tepat Waktu',
                      value: '$totalHadir',
                      subtitle: 'Dalam radius 100m',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppTheme.success,
                    ),
                    _buildKpiCard(
                      title: 'Luar Radius',
                      value: '$totalLuarRadius',
                      subtitle: 'Dalam pengawasan',
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppTheme.warning,
                    ),
                    _buildKpiCard(
                      title: 'Total Karyawan',
                      value: '${controller.rxTotalEmployees.value}',
                      subtitle: 'Terdaftar aktif',
                      icon: Icons.corporate_fare_rounded,
                      iconColor: AppTheme.secondary,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 28),

              // ===== Analytics Chart Section =====
              _buildAnalyticsCharts(context),
              const SizedBox(height: 32),

              // ===== Recent Activity Section =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Aktivitas Absensi Terbaru',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => controller.rxNavIndex.value = 2,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Obx(() {
                if (controller.rxIsLoading.value &&
                    controller.rxAttendanceLogs.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.rxAttendanceLogs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border, width: 1.5),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada data masuk hari ini.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final recentLogs = controller.rxAttendanceLogs.take(5).toList();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = recentLogs[index];
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
                    final punctuality = log.getPunctualityStatus(type);

                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.cardShadow,
                        border: Border.all(color: AppTheme.border, width: 1.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        leading: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.border,
                              width: 1.5,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: File(log.photoPath).existsSync()
                                ? Image.file(
                                    File(log.photoPath),
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                        title: Text(
                          log.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                log.dateTime.substring(11, 16),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.radar,
                                size: 13,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${log.distance.toStringAsFixed(1)}m',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                color: type == 'Masuk'
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFFF6B00),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (punctuality == 'Tepat Waktu' ||
                                        punctuality == 'Pulang Normal')
                                    ? AppTheme.success.withValues(alpha: 0.12)
                                    : (punctuality == 'Terlambat' ||
                                          punctuality == 'Pulang Cepat')
                                    ? AppTheme.warning.withValues(alpha: 0.12)
                                    : AppTheme.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                punctuality.toUpperCase(),
                                style: TextStyle(
                                  color:
                                      (punctuality == 'Tepat Waktu' ||
                                          punctuality == 'Pulang Normal')
                                      ? AppTheme.success
                                      : (punctuality == 'Terlambat' ||
                                            punctuality == 'Pulang Cepat')
                                      ? AppTheme.warning
                                      : AppTheme.danger,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    AuthController authController,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard HRD Administrator',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  authController.currentUser?.username ?? 'Administrator',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: iconColor, size: 22),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCharts(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analisis Tren Kehadiran Mingguan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 180,
            child: Obx(() {
              final trend = controller.rxWeeklyTrend;
              final dayNames = [
                'Sen',
                'Sel',
                'Rab',
                'Kam',
                'Jum',
                'Sab',
                'Min',
              ];

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dayNames.map((day) {
                  final data = trend[day] ?? {'percentage': 0.0, 'count': 0};
                  final pct = (data['percentage'] as num).toDouble();
                  final count = data['count'].toString();
                  return _buildBar(context, day, pct, count);
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
    BuildContext context,
    String day,
    double percentage,
    String count,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 28,
          height: 110 * percentage,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
