import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:checkly/modules/admin/controllers/admin_controller.dart';
import 'package:checkly/data/models/user_model.dart';
import 'package:checkly/core/theme/app_theme.dart';

class ManageEmployeeView extends GetView<AdminController> {
  const ManageEmployeeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Kelola Data Karyawan'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: Obx(() {
          final employees = controller.rxEmployees;

          if (controller.rxIsLoading.value && employees.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (employees.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.7,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_outline_rounded, size: 64, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada data karyawan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ketuk tombol + di kanan bawah untuk menambahkan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20.0),
            itemCount: employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final emp = employees[index];
              final hasPhoto = emp.photoProfile != null && File(emp.photoProfile!).existsSync();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(color: AppTheme.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    // Avatar profile
                    CircleAvatar(
                      backgroundColor: const Color(0xFFF1F5F9),
                      radius: 26,
                      backgroundImage: hasPhoto ? FileImage(File(emp.photoProfile!)) : null,
                      child: hasPhoto
                          ? null
                          : Text(
                              emp.username.substring(0, emp.username.length > 2 ? 2 : emp.username.length).toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                    ),
                    const SizedBox(width: 16),

                    // Detail info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.username,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            emp.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Password: ${emp.password}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary.withOpacity(0.8),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                          onPressed: () => _openEmployeeEditorBottomSheet(context, emp),
                          tooltip: 'Edit Karyawan',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
                          onPressed: () => _confirmDeleteEmployee(context, emp),
                          tooltip: 'Hapus Karyawan',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEmployeeEditorBottomSheet(context, null),
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _openEmployeeEditorBottomSheet(BuildContext context, UserModel? employee) {
    final isEdit = employee != null;
    final usernameCtrl = TextEditingController(text: employee?.username ?? '');
    final emailCtrl = TextEditingController(text: employee?.email ?? '');
    final passwordCtrl = TextEditingController(text: employee?.password ?? '');
    final rxObscure = true.obs;
    final rxPhotoPath = RxnString(employee?.photoProfile);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEdit ? 'Edit Data Karyawan' : 'Tambah Karyawan Baru',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 20),

              // Photo Editor
              Center(
                child: Obx(() {
                  final path = rxPhotoPath.value;
                  final hasPhoto = path != null && File(path).existsSync();

                  return GestureDetector(
                    onTap: () => _selectPhotoForEmployee(rxPhotoPath),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            backgroundColor: const Color(0xFFF1F5F9),
                            radius: 36,
                            backgroundImage: hasPhoto ? FileImage(File(path)) : null,
                            child: hasPhoto
                                ? null
                                : const Icon(Icons.person_rounded, color: AppTheme.primary, size: 40),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 10),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Username input
              const Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: usernameCtrl,
                readOnly: isEdit, // username is UNIQUE, prevent edit in SQLite to avoid conflicts
                decoration: InputDecoration(
                  hintText: 'Edit Username',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                  fillColor: isEdit ? const Color(0xFFF8FAFC) : null,
                  filled: isEdit,
                ),
              ),
              const SizedBox(height: 16),

              // Email input
              const Text('Alamat Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'karyawan@gmail.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 16),

              // Password input
              const Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Obx(() => TextField(
                controller: passwordCtrl,
                obscureText: rxObscure.value,
                decoration: InputDecoration(
                  hintText: 'Minimal 6 karakter',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      rxObscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                    ),
                    onPressed: () => rxObscure.toggle(),
                  ),
                ),
              )),
              const SizedBox(height: 28),

              // Action button
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
                          color: AppTheme.primary.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: controller.rxIsLoading.value ? null : () async {
                        final name = usernameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final pwd = passwordCtrl.text;

                        if (name.isEmpty || email.isEmpty || pwd.isEmpty) {
                          Get.snackbar('Validasi Gagal', 'Semua kolom wajib diisi', backgroundColor: Colors.redAccent, colorText: Colors.white);
                          return;
                        }

                        if (!email.endsWith('@gmail.com')) {
                          Get.snackbar('Validasi Gagal', 'Email wajib menggunakan domain @gmail.com', backgroundColor: Colors.redAccent, colorText: Colors.white);
                          return;
                        }

                        if (pwd.length < 6) {
                          Get.snackbar('Validasi Gagal', 'Password minimal terdiri dari 6 karakter', backgroundColor: Colors.redAccent, colorText: Colors.white);
                          return;
                        }

                        Get.back(); // close bottom sheet

                        if (isEdit) {
                          final updated = UserModel(
                            id: employee.id,
                            username: employee.username,
                            email: email,
                            password: pwd,
                            role: 'user',
                            photoProfile: rxPhotoPath.value,
                          );
                          await controller.editEmployee(updated);
                        } else {
                          // Standard creation
                          await controller.addEmployee(name, email, pwd);
                          if (rxPhotoPath.value != null && controller.rxEmployees.isNotEmpty) {
                            // If a photo was selected, update the newly added employee's photo
                            final newlyAdded = controller.rxEmployees.firstWhere((e) => e.username == name, orElse: () => controller.rxEmployees.first);
                            final withPhoto = UserModel(
                              id: newlyAdded.id,
                              username: newlyAdded.username,
                              email: newlyAdded.email,
                              password: newlyAdded.password,
                              role: newlyAdded.role,
                              photoProfile: rxPhotoPath.value,
                            );
                            await controller.editEmployee(withPhoto);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                      ),
                      child: controller.rxIsLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAH KARYAWAN',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _selectPhotoForEmployee(RxnString pathRx) async {
    final picker = ImagePicker();
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pilih Sumber Foto Karyawan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: const Text('Kamera', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                Get.back();
                final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                if (file != null) {
                  pathRx.value = file.path;
                }
              },
            ),
            const Divider(height: 1, color: AppTheme.border),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
              title: const Text('Galeri', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                Get.back();
                final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                if (file != null) {
                  pathRx.value = file.path;
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEmployee(BuildContext context, UserModel employee) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.surface,
        title: const Text('Hapus Karyawan', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        content: Text('Apakah Anda yakin ingin menghapus data karyawan "${employee.username}"? Semua riwayat absensi miliknya juga akan ikut terhapus.', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('BATAL', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              if (employee.id != null) {
                controller.deleteEmployee(employee.id!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('HAPUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
