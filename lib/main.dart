import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:mogot_app/core/services/storage_service.dart';

import 'features/home/dashboard_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 طلب صلاحية التخزين
  await requestStoragePermission();

  // 🔥 إنشاء ملفات التطبيق
  final storage = StorageService();

  await storage.read("transactions");

  await storage.read("customers");

  await storage.read("suppliers");

  runApp(MyApp());
}

// =========================
// 🔐 طلب الصلاحية
// =========================

Future<void> requestStoragePermission() async {

  // 🔥 إذا كانت الصلاحية موجودة
  if (await Permission.storage.isGranted) {
    return;
  }

  // 🔥 طلب الصلاحية
  final result =
      await Permission.storage.request();

  // 🔥 إذا رفض نهائيًا
  if (result.isPermanentlyDenied) {

    await openAppSettings();
  }
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      theme: ThemeData.dark(),

      builder: (context, child) {

        return Directionality(

          textDirection: TextDirection.rtl,

          child: child!,
        );
      },

      home: DashboardScreen(),
    );
  }
}