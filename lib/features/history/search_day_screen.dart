import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mogot_app/core/services/storage_service.dart';
import 'package:mogot_app/features/home/dashboard_screen.dart';

class SearchDayScreen extends StatefulWidget {

  @override
  _SearchDayScreenState createState() =>
      _SearchDayScreenState();
}

class _SearchDayScreenState
    extends State<SearchDayScreen> {

  DateTime? selectedDate;

  // =========================
  // 🔍 اختيار اليوم
  // =========================

  Future<void> pickDate() async {

    DateTime now = DateTime.now();

    DateTime? picked =
        await showDatePicker(

      context: context,

      initialDate: now,

      firstDate: DateTime(2020),

      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    selectedDate = picked;

    final path =
        await buildPath(picked);

    final folder =
        Directory(path);

    if (!await folder.exists()) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content: Text(
            "❌ لا يوجد بيانات لهذا اليوم",
          ),
        ),
      );

      return;
    }

    // 🔥 تفعيل وضع الأرشيف

    StorageService.setArchiveDate(
      picked,
    );

    // 🔥 فتح التطبيق كامل

    Navigator.pushAndRemoveUntil(

      context,

      MaterialPageRoute(
        builder: (_) =>
            DashboardScreen(),
      ),

      (route) => false,
    );
  }

  // =========================
  // 📁 بناء المسار
  // =========================

  Future<String> buildPath(
    DateTime date,
  ) async {

    final dir =
        await getExternalStorageDirectory();

    String month =
        "${date.year}-${date.month.toString().padLeft(2, '0')}";

    String day =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    return
        "${dir!.path}/MogotApp/$month/$day";
  }

  // =========================
  // 🏗️ البناء
  // =========================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("البحث في يوم"),
        centerTitle: true,
      ),

      body: Padding(

        padding: EdgeInsets.all(16),

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Icon(
              Icons.date_range,
              size: 80,
              color: Colors.blue,
            ),

            SizedBox(height: 20),

            Text(

              "اختر اليوم الذي تريد عرض بياناته",

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 16,
              ),
            ),

            SizedBox(height: 30),

            ElevatedButton(

              onPressed: pickDate,

              style:
                  ElevatedButton.styleFrom(
                minimumSize:
                    Size(double.infinity, 50),
              ),

              child: Text(
                "اختيار التاريخ",
              ),
            ),
          ],
        ),
      ),
    );
  }
}