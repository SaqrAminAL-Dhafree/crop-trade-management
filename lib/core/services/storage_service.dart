import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';

class StorageService {

  // 🔥 تاريخ الأرشيف الحالي
  static DateTime? archiveDate;

  // 🔥 تفعيل وضع الأرشيف
  static void setArchiveDate(
    DateTime date,
  ) {
    archiveDate = date;
  }

  // 🔥 الخروج من وضع الأرشيف
  static void clearArchiveDate() {
    archiveDate = null;
  }

  // =========================
  // 📁 المسار الأساسي
  // =========================

  Future<String> _basePath() async {

    final dir =
        await getExternalStorageDirectory();

    return dir!.path;
  }

  // =========================
  // 📅 الشهر
  // =========================

  String _month() {

    final now =
        archiveDate ?? DateTime.now();

    return
        "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  // =========================
  // 📅 اليوم
  // =========================

  String _day() {

    final now =
        archiveDate ?? DateTime.now();

    return
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // =========================
  // 📁 مجلد التطبيق
  // =========================

  Future<Directory> _getAppFolder() async {

    final base =
        await _basePath();

    final dir =
        Directory("$base/MogotApp");

    if (!await dir.exists()) {

      await dir.create(
        recursive: true,
      );
    }

    return dir;
  }

  // =========================
  // 📁 مجلد الشهر
  // =========================

  Future<Directory> _getMonthFolder() async {

    final appDir =
        await _getAppFolder();

    final dir = Directory(
      "${appDir.path}/${_month()}",
    );

    if (!await dir.exists()) {

      await dir.create(
        recursive: true,
      );
    }

    return dir;
  }

  // =========================
  // 📁 مجلد اليوم
  // =========================

  Future<Directory> _getDayFolder() async {

    final monthDir =
        await _getMonthFolder();

    final dir = Directory(
      "${monthDir.path}/${_day()}",
    );

    if (!await dir.exists()) {

      await dir.create(
        recursive: true,
      );
    }

    return dir;
  }

  // =========================
  // 📄 إنشاء الملف
  // =========================

  Future<File> _getFile(
    String name,
  ) async {

    final dir =
        await _getDayFolder();

    final file =
        File("${dir.path}/$name.json");

    if (!await file.exists()) {

      await file.writeAsString(
        jsonEncode([]),
      );
    }

    return file;
  }

  // =========================
  // 💾 حفظ
  // =========================

  Future<void> save(
    String name,
    List<Map<String, dynamic>> data,
  ) async {

    final file =
        await _getFile(name);

    await file.writeAsString(
      jsonEncode(data),
    );
  }

  // =========================
  // 📥 قراءة
  // =========================

  Future<List<dynamic>> read(
    String name,
  ) async {

    try {

      final file =
          await _getFile(name);

      final content =
          await file.readAsString();

      return jsonDecode(content);

    } catch (e) {

      return [];
    }
  }
}