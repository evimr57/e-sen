import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:esen/core/database/db_helper.dart';
import 'package:esen/data/models/user_model.dart';
import 'package:esen/routes/app_pages.dart';

class AuthController extends GetxController {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final rxRole = 'user'.obs; // Default role
  final rxIsLoading = false.obs;
  final rxObscurePassword = true.obs; // Toggle password visibility

  // Current active user
  final rxCurrentUser = Rxn<UserModel>();
  UserModel? get currentUser => rxCurrentUser.value;

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Gagal',
        'Email/Username dan Password wajib diisi',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Constraint: Employee must use email ending with @gmail.com
    if (username != 'admin' && !username.endsWith('@gmail.com')) {
      Get.snackbar(
        'Akses Ditolak',
        'Karyawan wajib masuk menggunakan email @gmail.com',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    rxIsLoading.value = true;
    try {
      final user = await DbHelper.instance.loginUser(username, password);
      if (user != null) {
        rxCurrentUser.value = user;
        usernameController.clear();
        passwordController.clear();

        Get.snackbar(
          'Sukses',
          'Selamat datang kembali, ${user.username}!',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        if (user.role == 'admin') {
          Get.offAllNamed(Routes.ADMIN_DASHBOARD);
        } else {
          Get.offAllNamed(Routes.USER_DASHBOARD);
        }
      } else {
        Get.snackbar(
          'Gagal Login',
          'Kredensial atau Password salah',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan saat login: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }

  void register() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final role = rxRole.value;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Gagal',
        'Semua kolom wajib diisi',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Constraint: Employee registration must use @gmail.com
    if (!email.endsWith('@gmail.com')) {
      Get.snackbar(
        'Gagal',
        'Pendaftaran karyawan wajib menggunakan email @gmail.com',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar(
        'Gagal',
        'Konfirmasi password tidak cocok',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    rxIsLoading.value = true;
    try {
      final isTaken = await DbHelper.instance.isUsernameTaken(username);
      if (isTaken) {
        Get.snackbar(
          'Gagal',
          'Username sudah terdaftar',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final newUser = UserModel(
        username: username,
        email: email,
        password: password,
        role: role,
      );

      await DbHelper.instance.registerUser(newUser);

      Get.snackbar(
        'Sukses',
        'Registrasi berhasil! Silakan login.',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Reset fields
      usernameController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();

      Get.offNamed(Routes.LOGIN);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan saat registrasi: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      rxIsLoading.value = false;
    }
  }

  void logout() {
    rxCurrentUser.value = null;
    Get.offAllNamed(Routes.LOGIN);
    Get.snackbar(
      'Logout',
      'Anda berhasil keluar',
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<bool> resetPassword(String identifier, String newPassword) async {
    rxIsLoading.value = true;
    try {
      final db = await DbHelper.instance.database;
      final maps = await db.query(
        'users',
        where: 'LOWER(username) = ? OR LOWER(email) = ?',
        whereArgs: [identifier.toLowerCase(), identifier.toLowerCase()],
      );
      if (maps.isEmpty) {
        Get.snackbar(
          'Gagal',
          'Username atau email tidak ditemukan',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }

      final userMap = maps.first;
      final user = UserModel.fromMap(userMap);
      final updated = UserModel(
        id: user.id,
        username: user.username,
        email: user.email,
        password: newPassword,
        role: user.role,
        photoProfile: user.photoProfile,
      );
      await DbHelper.instance.updateUser(updated);
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal reset password: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      rxIsLoading.value = false;
    }
  }
}
