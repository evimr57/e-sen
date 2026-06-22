import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:esen/modules/admin/controllers/admin_controller.dart';
import 'package:esen/data/models/work_schedule_model.dart';
import 'package:esen/core/theme/app_theme.dart';

class ManageCoordinateView extends GetView<AdminController> {
  const ManageCoordinateView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Lokasi & Jadwal Kerja'),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'Koordinat Utama'),
              Tab(text: 'Jadwal Kerja'),
            ],
          ),
        ),
        body: const TabBarView(children: [_CoordinateTab(), _ScheduleTab()]),
      ),
    );
  }
}

// =====================================================================
// TAB 1: Koordinat Utama (existing functionality, unchanged)
// =====================================================================
class _CoordinateTab extends GetView<AdminController> {
  const _CoordinateTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Visualisasi Radius Peta',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              const Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Ketuk peta',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          Obx(() {
            final mapCenter = LatLng(
              controller.rxFormLatitude.value,
              controller.rxFormLongitude.value,
            );
            final radius = controller.rxFormRadius.value;

            return Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                key: Key('${mapCenter.latitude}_${mapCenter.longitude}'),
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: 16.5,
                  onTap: (tapPosition, latLng) {
                    controller.latitudeController.text = latLng.latitude
                        .toStringAsFixed(6);
                    controller.longitudeController.text = latLng.longitude
                        .toStringAsFixed(6);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.esen.app',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: mapCenter,
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderStrokeWidth: 1.5,
                        borderColor: AppTheme.primary,
                        useRadiusInMeter: true,
                        radius: radius,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: mapCenter,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.danger,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // 2. Editor Card Form
          Container(
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
                Text(
                  'Konfigurasi Titik Absensi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Name Field
                const Text(
                  'Nama Lokasi / Kantor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.nameController,
                  decoration: const InputDecoration(
                    hintText: 'Misal: Kantor Cabang Sudirman',
                    prefixIcon: Icon(
                      Icons.business_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Latitude & Longitude Fields
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Latitude',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: controller.latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: '-6.175392',
                              prefixIcon: Icon(
                                Icons.map_rounded,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Longitude',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: controller.longitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: '106.827153',
                              prefixIcon: Icon(
                                Icons.explore_rounded,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Radius Limit Field
                const Text(
                  'Batas Radius (Meter)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.radiusController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Rekomendasi: 100',
                    prefixIcon: Icon(
                      Icons.radar_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Gunakan Lokasi GPS Saya Saat Ini
                Obx(() {
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: controller.rxIsLoading.value
                          ? null
                          : controller.fetchCurrentLocationForForm,
                      icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                      label: const Text('Ambil Koordinat Saya Saat Ini'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(
                          color: AppTheme.primary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Submit Save Button
                Obx(() {
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: controller.rxIsLoading.value
                            ? null
                            : controller.saveCoordinate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                        ),
                        child: controller.rxIsLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'SIMPAN TITIK KOORDINAT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 3. Active coordinates detail summary
          Text(
            'Koordinat Aktif Kantor',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),

          Obx(() {
            if (controller.rxCoordinates.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada koordinat kantor tersimpan.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            final coord = controller.rxCoordinates.first;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(color: AppTheme.border, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppTheme.success,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          coord.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Latitude',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${coord.latitude}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Longitude',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${coord.longitude}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Batas Radius',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${coord.radiusMeters} meter',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// =====================================================================
// TAB 2: Jadwal Kerja (new feature)
// =====================================================================
class _ScheduleTab extends GetView<AdminController> {
  const _ScheduleTab();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.rxWorkSchedules.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final schedules = controller.rxWorkSchedules;

      return ListView.builder(
        padding: const EdgeInsets.all(20.0),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _DayScheduleCard(
              key: ValueKey(schedule.dayOfWeek),
              schedule: schedule,
            ),
          );
        },
      );
    });
  }
}

class _DayScheduleCard extends StatefulWidget {
  final WorkScheduleModel schedule;

  const _DayScheduleCard({super.key, required this.schedule});

  @override
  State<_DayScheduleCard> createState() => _DayScheduleCardState();
}

class _DayScheduleCardState extends State<_DayScheduleCard> {
  bool _expanded = false;

  late bool _isActive;
  late TextEditingController _startTimeCtrl;
  late TextEditingController _endTimeCtrl;
  late TextEditingController _locationNameCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  late TextEditingController _radiusCtrl;

  @override
  void initState() {
    super.initState();
    _syncFromSchedule(widget.schedule);
  }

  @override
  void didUpdateWidget(covariant _DayScheduleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schedule != widget.schedule) {
      _syncFromSchedule(widget.schedule);
    }
  }

  void _syncFromSchedule(WorkScheduleModel s) {
    _isActive = s.isActive;
    _startTimeCtrl = TextEditingController(text: s.startTime);
    _endTimeCtrl = TextEditingController(text: s.endTime);
    _locationNameCtrl = TextEditingController(text: s.locationName);
    _latCtrl = TextEditingController(text: s.latitude.toString());
    _lngCtrl = TextEditingController(text: s.longitude.toString());
    _radiusCtrl = TextEditingController(text: s.radiusMeters.toString());
  }

  @override
  void dispose() {
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _locationNameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.elementAtOrNull(0) ?? '8') ?? 8,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      setState(() {
        ctrl.text = '$hh:$mm';
      });
    }
  }

  void _save() {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    final rad = double.tryParse(_radiusCtrl.text.trim());

    if (lat == null || lng == null || rad == null) {
      Get.snackbar(
        'Error',
        'Format koordinat atau radius harus angka desimal',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final updated = widget.schedule.copyWith(
      isActive: _isActive,
      startTime: _startTimeCtrl.text.trim(),
      endTime: _endTimeCtrl.text.trim(),
      locationName: _locationNameCtrl.text.trim().isEmpty
          ? 'Lokasi Kerja'
          : _locationNameCtrl.text.trim(),
      latitude: lat,
      longitude: lng,
      radiusMeters: rad,
    );

    Get.find<AdminController>().saveWorkSchedule(updated);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Column(
        children: [
          // ===== Collapsed Header (always visible) =====
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _isActive
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : AppTheme.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.dayName.substring(0, 3),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _isActive
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.dayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isActive
                              ? '${s.startTime} - ${s.endTime} · ${s.locationName}'
                              : 'Libur',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isActive
                                ? AppTheme.textSecondary
                                : AppTheme.warning,
                            fontWeight: _isActive
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // ===== Expanded Detail Form =====
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: _buildExpandedForm(context),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Active toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hari Kerja Aktif',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Switch(
                value: _isActive,
                activeThumbColor: AppTheme.primary,
                onChanged: (val) => setState(() => _isActive = val),
              ),
            ],
          ),

          if (_isActive) ...[
            const SizedBox(height: 16),

            // Start / End time
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    label: 'Jam Masuk',
                    controller: _startTimeCtrl,
                    icon: Icons.login_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeField(
                    label: 'Jam Pulang',
                    controller: _endTimeCtrl,
                    icon: Icons.logout_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location name
            const Text(
              'Nama Lokasi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _locationNameCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Misal: Kantor Cabang Sudirman',
                isDense: true,
                prefixIcon: Icon(
                  Icons.business_rounded,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mini map preview
            const Text(
              'Lokasi & Radius Absensi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            _buildMiniMap(),
            const SizedBox(height: 12),

            // Lat / Lng / Radius fields
            Row(
              children: [
                Expanded(
                  child: _buildSmallNumberField(
                    label: 'Latitude',
                    controller: _latCtrl,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSmallNumberField(
                    label: 'Longitude',
                    controller: _lngCtrl,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSmallNumberField(
                    label: 'Radius (m)',
                    controller: _radiusCtrl,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          // Save button
          Obx(() {
            final isLoading = Get.find<AdminController>().rxIsLoading.value;
            return SizedBox(
              width: double.infinity,
              height: 46,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'SIMPAN JADWAL ${widget.schedule.dayName.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pickTime(controller),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: Icon(icon, size: 16, color: AppTheme.textSecondary),
            ),
            child: Text(
              controller.text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallNumberField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          style: const TextStyle(fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
          onChanged: (_) => setState(() {}), // refresh mini map live
        ),
      ],
    );
  }

  Widget _buildMiniMap() {
    final lat = double.tryParse(_latCtrl.text) ?? -6.175392;
    final lng = double.tryParse(_lngCtrl.text) ?? 106.827153;
    final radius = double.tryParse(_radiusCtrl.text) ?? 100.0;
    final center = LatLng(lat, lng);

    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        key: Key('map_${widget.schedule.dayOfWeek}_${lat}_$lng'),
        options: MapOptions(
          initialCenter: center,
          initialZoom: 15.5,
          onTap: (tapPosition, latLng) {
            setState(() {
              _latCtrl.text = latLng.latitude.toStringAsFixed(6);
              _lngCtrl.text = latLng.longitude.toStringAsFixed(6);
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.esen.app',
          ),
          CircleLayer(
            circles: [
              CircleMarker(
                point: center,
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderStrokeWidth: 1.5,
                borderColor: AppTheme.primary,
                useRadiusInMeter: true,
                radius: radius,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 32,
                height: 32,
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.danger,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
