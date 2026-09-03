import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FileService {

  // =========================
  // 📁 مجلد التطبيق الرئيسي
  // =========================

  Future<Directory> _getAppDir() async {

    final dir =
        await getExternalStorageDirectory();

    final appFolder = Directory(
      "${dir!.path}/MogotApp",
    );

    if (!await appFolder.exists()) {

      await appFolder.create(
        recursive: true,
      );
    }

    return appFolder;
  }

  // =========================
  // 📁 مجلد الأرشيف
  // =========================

  Future<Directory> _getArchiveDir() async {

    final appDir =
        await _getAppDir();

    final archive = Directory(
      "${appDir.path}/archive",
    );

    if (!await archive.exists()) {

      await archive.create(
        recursive: true,
      );
    }

    return archive;
  }

  // =========================
  // 📅 الشهر
  // =========================

  String _getMonth() {

    final now = DateTime.now();

    return
        "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  // =========================
  // 📅 اليوم
  // =========================

  String _getDay() {

    final now = DateTime.now();

    return
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // =========================
  // 📁 مجلد الشهر
  // =========================

  Future<Directory> _getMonthFolder() async {

    final archive =
        await _getArchiveDir();

    final monthDir = Directory(
      "${archive.path}/${_getMonth()}",
    );

    if (!await monthDir.exists()) {

      await monthDir.create(
        recursive: true,
      );
    }

    return monthDir;
  }

  // =========================
  // 📁 مجلد اليوم
  // =========================

  Future<Directory>
      getTodayArchiveFolder() async {

    final monthDir =
        await _getMonthFolder();

    final todayDir = Directory(
      "${monthDir.path}/${_getDay()}",
    );

    if (!await todayDir.exists()) {

      await todayDir.create(
        recursive: true,
      );
    }

    return todayDir;
  }

  // =========================
  // 📁 مجلد اليوم الحالي
  // =========================

  Future<Directory>
      getCurrentDayFolder() async {

    final appDir =
        await _getAppDir();

    final currentDir = Directory(
      "${appDir.path}/current",
    );

    if (!await currentDir.exists()) {

      await currentDir.create(
        recursive: true,
      );
    }

    return currentDir;
  }

  // =========================
  // 💾 حفظ
  // =========================

  Future<void> saveFile(
    String fileName,
    List data,
  ) async {

    final folder =
        await getCurrentDayFolder();

    final file = File(
      "${folder.path}/$fileName",
    );

    await file.writeAsString(
      jsonEncode(data),
    );
  }

  // =========================
  // 📥 قراءة
  // =========================

  Future<List> readFile(
    String fileName,
  ) async {

    final folder =
        await getCurrentDayFolder();

    final file = File(
      "${folder.path}/$fileName",
    );

    if (!await file.exists()) {
      return [];
    }

    final content =
        await file.readAsString();

    return jsonDecode(content);
  }

  // =========================
  // 📦 أرشفة اليوم
  // =========================

  Future<void> archiveCurrentDay({

    required List transactions,

    required List customers,

    required List suppliers,

  }) async {

    final archiveFolder =
        await getTodayArchiveFolder();

    await File(
      "${archiveFolder.path}/transactions.json",
    ).writeAsString(
      jsonEncode(transactions),
    );

    await File(
      "${archiveFolder.path}/customers.json",
    ).writeAsString(
      jsonEncode(customers),
    );

    await File(
      "${archiveFolder.path}/suppliers.json",
    ).writeAsString(
      jsonEncode(suppliers),
    );
  }

  // =========================
  // 🔍 هل اليوم موجود؟
  // =========================

  Future<bool> isTodayArchived() async {

    final archive =
        await _getArchiveDir();

    final month =
        _getMonth();

    final day =
        _getDay();

    final path =
        "${archive.path}/$month/$day";

    final dir =
        Directory(path);

    return await dir.exists();
  }

  // =========================
  // 🧹 تنظيف اليوم الحالي
  // =========================

  Future<void> clearCurrentDay() async {

    final folder =
        await getCurrentDayFolder();

    final files =
        folder.listSync();

    for (var f in files) {

      if (f is File) {

        await f.delete();
      }
    }
  }
}