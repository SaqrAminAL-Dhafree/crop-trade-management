import 'package:flutter/material.dart';

import '../suppliers/views/supplier_screen.dart';
import '../customers/views/customers_screen.dart';
import '../history/history_home_screen.dart';

import '../../storage/file_service.dart';

import '../transactions/services/transaction_service.dart';
import '../customers/controllers/customer_service.dart';
import '../suppliers/controllers/supplier_service.dart';

import '../../core/services/storage_service.dart';

class DashboardScreen extends StatefulWidget {

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {

  bool _isLoading = false;

  // =====================
  // 🔥 هل نحن في وضع الأرشيف؟
  // =====================

  bool get isArchiveMode =>
      StorageService.archiveDate != null;

  // =====================
  // 🧱 بناء البطاقة
  // =====================

  Widget buildCard({

    required String title,

    required IconData icon,

    required VoidCallback onTap,

    Color? color,
  }) {

    return GestureDetector(

      onTap:
          _isLoading
              ? null
              : onTap,

      child: Card(

        shape:
            RoundedRectangleBorder(

          borderRadius:
              BorderRadius.circular(16),
        ),

        elevation: 4,

        child: Container(

          padding:
              EdgeInsets.all(12),

          child: Column(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              Icon(

                icon,

                size: 36,

                color:
                    color ??
                    Colors.blue,
              ),

              SizedBox(height: 8),

              Flexible(

                child: Text(

                  title,

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),

                  textAlign:
                      TextAlign.center,

                  maxLines: 2,

                  overflow:
                      TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================
  // 📅 فتح يوم جديد
  // =====================

  Future<void> _openNewDay() async {

    // 🔥 منع فتح يوم جديد داخل الأرشيف
    if (isArchiveMode) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content: Text(
            "❌ لا يمكن فتح يوم جديد أثناء وضع الأرشيف",
          ),

          backgroundColor:
              Colors.red,
        ),
      );

      return;
    }

    final confirm =
        await showDialog<bool>(

      context: context,

      builder: (ctx) =>
          AlertDialog(

        title: Text("تأكيد"),

        content: Text(

          "هل أنت متأكد من فتح يوم جديد؟\nسيتم حفظ بيانات اليوم وحذفها.",
        ),

        actions: [

          TextButton(

            onPressed: () =>
                Navigator.pop(
              ctx,
              false,
            ),

            child: Text("إلغاء"),
          ),

          TextButton(

            onPressed: () =>
                Navigator.pop(
              ctx,
              true,
            ),

            child: Text(

              "تأكيد",

              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {

      final fileService =
          FileService();

      final exists =
          await fileService
              .isTodayArchived();

      if (!mounted) return;

      if (exists) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(

            content: Text(
              "⚠️ ما زلنا في نفس اليوم، لا تستعجل",
            ),

            backgroundColor:
                Colors.orange,
          ),
        );

        return;
      }

      final transactionService =
          TransactionService();

      final customerService =
          CustomerService();

      final supplierService =
          SupplierService();

      // 1️⃣ جلب بيانات اليوم الحالي

      final transactions =
          await transactionService
              .getTransactions();

      final customers =
          await customerService
              .getCustomers();

      final suppliers =
          await supplierService
              .getSuppliers();

      if (!mounted) return;

      // 2️⃣ أرشفة اليوم

      await fileService.archiveCurrentDay(

        transactions:
            transactions
                .map((e) => e.toJson())
                .toList(),

        customers:
            customers
                .map((e) => e.toJson())
                .toList(),

        suppliers:
            suppliers
                .map((e) => e.toJson())
                .toList(),
      );

      if (!mounted) return;

      // 3️⃣ تنظيف اليوم الحالي

      await fileService.clearCurrentDay();

      if (!mounted) return;

      // 4️⃣ إعادة تهيئة

      await transactionService
          .saveTransactions([]);

      await customerService
          .saveCustomers([]);

      await supplierService
          .saveSuppliers([]);

      if (!mounted) return;

      // 5️⃣ إشعار نجاح

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content: Text(
            "✅ تم فتح يوم جديد بنجاح",
          ),

          backgroundColor:
              Colors.green,
        ),
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content: Text(
            "❌ حدث خطأ: ${e.toString()}",
          ),

          backgroundColor:
              Colors.red,
        ),
      );

    } finally {

      if (mounted) {

        setState(
          () => _isLoading = false,
        );
      }
    }
  }

  // =====================
  // 🔥 الخروج من وضع الأرشيف
  // =====================

  void exitArchiveMode() {

    StorageService.clearArchiveDate();

    Navigator.pushReplacement(

      context,

      MaterialPageRoute(
        builder: (_) =>
            DashboardScreen(),
      ),
    );
  }

  // =====================
  // 🏗️ البناء
  // =====================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Text("لوحة التحكم"),

        actions: [

          // 🔥 زر الخروج من الأرشيف
          if (isArchiveMode)

            IconButton(

              icon: Icon(
                Icons.close,
              ),

              onPressed:
                  exitArchiveMode,
            ),
        ],
      ),

      body: Stack(

        children: [

          Column(

            children: [

              // 🔥 شريط الأرشيف
              if (isArchiveMode)

                Container(

                  width: double.infinity,

                  color: Colors.orange,

                  padding:
                      EdgeInsets.all(10),

                  child: Text(

                    "📂 وضع الأرشيف - ${StorageService.archiveDate!.year}-${StorageService.archiveDate!.month.toString().padLeft(2, '0')}-${StorageService.archiveDate!.day.toString().padLeft(2, '0')}",

                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),

                    textAlign:
                        TextAlign.center,
                  ),
                ),

              Expanded(

                child: Padding(

                  padding:
                      const EdgeInsets.all(16),

                  child: Column(

                    children: [

                      Expanded(

                        child: GridView.count(

                          crossAxisCount: 2,

                          crossAxisSpacing: 15,

                          mainAxisSpacing: 15,

                          children: [

                            // 🟢 المقاوته

                            buildCard(

                              title: "الرعيه",

                              icon: Icons.store,

                              color: Colors.green,

                              onTap: () =>
                                  Navigator.push(

                                context,

                                MaterialPageRoute(
                                  builder: (_) =>
                                      SupplierScreen(),
                                ),
                              ),
                            ),

                            // 🔵 الزبائن

                            buildCard(

                              title: "الزبائن",

                              icon: Icons.people,

                              color: Colors.blue,

                              onTap: () =>
                                  Navigator.push(

                                context,

                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomersScreen(),
                                ),
                              ),
                            ),

                            // 🛒 العمليات

                            buildCard(

                              title: "عمليات",

                              icon: Icons.shopping_cart,

                              color: Colors.purple,

                              onTap: () =>
                                  Navigator.push(

                                context,

                                MaterialPageRoute(
                                  builder: (_) =>
                                      HistoryHomeScreen(),
                                ),
                              ),
                            ),

                            // 📅 فتح يوم جديد

                            buildCard(

                              title: "فتح يوم جديد",

                              icon:
                                  Icons.add_circle_outline,

                              color: Colors.orange,

                              onTap:
                                  _openNewDay,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 15),

                      // =========================
                      // 🌿 بطاقة نشوان الصلاحي
                      // =========================

                    Container(

  width: double.infinity,

  padding: EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  ),

  decoration: BoxDecoration(

    color: Color(0xff1E1E1E),

    borderRadius:
        BorderRadius.circular(16),

    border: Border.all(
      color: Colors.green.shade700,
      width: 1.2,
    ),

    boxShadow: [

      BoxShadow(

        color: Colors.black26,

        blurRadius: 6,

        offset: Offset(0, 3),
      ),
    ],
  ),

  child: Column(

    mainAxisSize: MainAxisSize.min,

    children: [

      Row(

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Icon(

            Icons.eco,

            color: Colors.greenAccent,

            size: 22,
          ),

          SizedBox(width: 8),

          Text(

            "نشوان الصلاحي",

            style: TextStyle(

              fontSize: 18,

              fontWeight:
                  FontWeight.bold,

              color: Colors.white,
            ),
          ),
        ],
      ),

      SizedBox(height: 8),

      Text(

        "قطل • نقفة • صدور • عود",

        textAlign: TextAlign.center,

        style: TextStyle(

          fontSize: 14,

          color: Colors.white70,

          fontWeight:
              FontWeight.w600,
        ),
      ),

      SizedBox(height: 10),

      Text(

        "نشوان لديكم ... لا خوف عليكم",

        textAlign: TextAlign.center,

        style: TextStyle(

          fontSize: 13,

          color: Colors.greenAccent,

          fontWeight:
              FontWeight.bold,
        ),
      ),
    ],
  ),
)
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ✅ طبقة التحميل

          if (_isLoading)

            Container(

              color:
                  Colors.black.withOpacity(
                0.4,
              ),

              child: Center(

                child: Column(

                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    CircularProgressIndicator(
                      color: Colors.white,
                    ),

                    SizedBox(height: 16),

                    Text(

                      "جاري فتح يوم جديد...",

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}