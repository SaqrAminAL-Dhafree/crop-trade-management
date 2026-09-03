import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

// Models
import '../customers/models/customer_model.dart';

// Services
import '../customers/controllers/customer_service.dart';
import '../transactions/services/transaction_service.dart';

// Details Screen
import '../customers/views/customer_details_screen.dart';

// =====================
// 🖨️ دالة توليد PDF
// =====================
Future<pw.Document> generateDebtsPdf({
  required List<Map<String, dynamic>> data,
  required double totalDebts,
}) async {

  final fontData = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  const PdfColor primaryColor = PdfColor.fromInt(0xFF1A237E);
  const PdfColor debtColor    = PdfColor.fromInt(0xFFB71C1C);
  const PdfColor paidColor    = PdfColor.fromInt(0xFF1B5E20);
  const PdfColor summaryBg    = PdfColor.fromInt(0xFFF3F4F6);
  const PdfColor dividerColor = PdfColor.fromInt(0xFFBBBBBB);

  pw.TextStyle styleSmall([PdfColor? color]) =>
      pw.TextStyle(font: ttf, fontSize: 9, color: color ?? PdfColors.black);

  pw.TextStyle styleBold([PdfColor? color]) => pw.TextStyle(
        font: ttf,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: color ?? PdfColors.black,
      );

  final pdf = pw.Document();
  final now = DateTime.now();
  final reportNumber =
      "${now.year}${now.month}${now.day}-${now.hour}${now.minute}";

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(24),

      header: (context) => pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            decoration: const pw.BoxDecoration(color: primaryColor),
            child: pw.Column(
              children: [
                pw.Text(
                  " حراج نشوان الصلاحي",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "تقرير ديون الزبائن",
                  style: pw.TextStyle(
                      font: ttf, fontSize: 13, color: PdfColors.white),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: summaryBg,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text("رقم التقرير: $reportNumber",
                    style: styleSmall(const PdfColor.fromInt(0xFF1565C0))),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: summaryBg,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                    "التاريخ: ${now.year}-${now.month}-${now.day}",
                    style: styleSmall(const PdfColor.fromInt(0xFF1565C0))),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: dividerColor, thickness: 1),
        ],
      ),

      footer: (context) => pw.Column(
        children: [
          pw.Divider(color: dividerColor, thickness: 0.5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("حراج نشوان  الصلاحي © جميع الحقوق محفوظة ",
                  style: styleSmall(PdfColors.grey600)),
              pw.Text(
                  "صفحة ${context.pageNumber} من ${context.pagesCount}",
                  style: styleSmall(PdfColors.grey600)),
            ],
          ),
        ],
      ),

      build: (context) => [

        pw.SizedBox(height: 8),

        // بطاقة الإجمالي
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: debtColor,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("إجمالي الديون",
                  style: pw.TextStyle(
                      font: ttf, fontSize: 14, color: PdfColors.white)),
              pw.Text(
                totalDebts.toStringAsFixed(0),
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 16),

        // عنوان الجدول
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: primaryColor,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            "قائمة الزبائن والديون",
            style: pw.TextStyle(
              font: ttf,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),

        pw.SizedBox(height: 10),

        // الجدول الرئيسي
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(
            font: ttf,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: primaryColor),
          cellDecoration: (index, data, rowNum) => pw.BoxDecoration(
            color: rowNum.isOdd
                ? PdfColors.white
                : const PdfColor.fromInt(0xFFEEF2FF),
          ),
          cellStyle: styleSmall(),
          cellAlignment: pw.Alignment.center,
          border: pw.TableBorder.all(color: dividerColor, width: 0.5),
          cellPadding: const pw.EdgeInsets.symmetric(
              vertical: 6, horizontal: 4),
          headers: ["المتبقي", "المدفوع", "الإجمالي", "الزبون"],
          data: data.map((e) {
            final Customer c = e["customer"];
            return [
              e["remaining"].toStringAsFixed(0),
              e["paid"].toStringAsFixed(0),
              e["total"].toStringAsFixed(0),
              c.name,
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 16),

        // ملخص إحصائي
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: summaryBg,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: dividerColor),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(children: [
                pw.Text("عدد الزبائن",
                    style: styleSmall(PdfColors.grey700)),
                pw.SizedBox(height: 4),
                pw.Text(data.length.toString(),
                    style: styleBold(primaryColor)),
              ]),
              pw.Column(children: [
                pw.Text("عدد المدينين",
                    style: styleSmall(PdfColors.grey700)),
                pw.SizedBox(height: 4),
                pw.Text(
                  data.where((e) => e["remaining"] > 0).length.toString(),
                  style: styleBold(debtColor),
                ),
              ]),
              pw.Column(children: [
                pw.Text("عدد المسددين",
                    style: styleSmall(PdfColors.grey700)),
                pw.SizedBox(height: 4),
                pw.Text(
                  data.where((e) => e["remaining"] <= 0).length.toString(),
                  style: styleBold(paidColor),
                ),
              ]),
              pw.Column(children: [
                pw.Text("إجمالي المدفوع",
                    style: styleSmall(PdfColors.grey700)),
                pw.SizedBox(height: 4),
                pw.Text(
                  data
                      .fold<double>(0, (sum, e) => sum + e["paid"])
                      .toStringAsFixed(0),
                  style: styleBold(paidColor),
                ),
              ]),
              pw.Column(children: [
                pw.Text("إجمالي الديون",
                    style: styleSmall(PdfColors.grey700)),
                pw.SizedBox(height: 4),
                pw.Text(totalDebts.toStringAsFixed(0),
                    style: styleBold(debtColor)),
              ]),
            ],
          ),
        ),
      ],
    ),
  );

  return pdf;
}

// =====================
// 📱 الصفحة الرئيسية
// =====================
class TodayDebtsScreen extends StatefulWidget {
  @override
  _TodayDebtsScreenState createState() => _TodayDebtsScreenState();
}

class _TodayDebtsScreenState extends State<TodayDebtsScreen> {

  final CustomerService customerService = CustomerService();
  final TransactionService transactionService = TransactionService();

  List<Customer> customers = [];
  List transactions = [];

  bool showOnlyDebtors = true;
  double totalDebts = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    customers = await customerService.getCustomers();
    transactions = await transactionService.getTransactions();
    calculateTotalDebts();
    setState(() {});
  }

  void calculateTotalDebts() {
    totalDebts = 0;
    for (var c in customers) {
      double remaining = getCustomerDebt(c.id);
      if (remaining > 0) totalDebts += remaining;
    }
  }

  double getCustomerDebt(String customerId) {
    double total = 0;
    double paid  = 0;
    for (var t in transactions) {
      if (t.customerId == customerId) {
        total += t.quantity * t.price;
        paid  += t.paidAmount;
      }
    }
    return total - paid;
  }

  List<Map<String, dynamic>> buildData() {
    List<Map<String, dynamic>> data = [];

    for (var c in customers) {
      double total = 0;
      double paid  = 0;

      for (var t in transactions) {
        if (t.customerId == c.id) {
          total += t.quantity * t.price;
          paid  += t.paidAmount;
        }
      }

      double remaining = total - paid;
      if (showOnlyDebtors && remaining <= 0) continue;

      data.add({
        "customer": c,
        "total": total,
        "paid": paid,
        "remaining": remaining,
      });
    }

    data.sort((a, b) => b["remaining"].compareTo(a["remaining"]));
    return data;
  }

  List<DataRow> buildRows() {
    return buildData().map((e) {
      final Customer c = e["customer"];
      return DataRow(
        onSelectChanged: (_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailsScreen(customer: c),
            ),
          );
        },
        cells: [
          DataCell(Text(c.name)),
          DataCell(Text(e["total"].toStringAsFixed(0))),
          DataCell(Text(e["paid"].toStringAsFixed(0))),
          DataCell(Text(
            e["remaining"].toStringAsFixed(0),
            style: TextStyle(
              color: e["remaining"] > 0 ? Colors.red : Colors.green,
            ),
          )),
        ],
      );
    }).toList();
  }

  // ✅ تصدير PDF
  Future<void> exportPdf() async {
    final data = buildData();

    final pdf = await generateDebtsPdf(
      data: data,
      totalDebts: totalDebts,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ديون اليوم"),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            tooltip: "تصدير PDF",
            onPressed: exportPdf,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: showOnlyDebtors,
                  onChanged: (val) {
                    setState(() {
                      showOnlyDebtors = val!;
                    });
                  },
                ),
                Text("عرض فقط من عليهم دين"),
              ],
            ),
            SizedBox(height: 10),
            Text(
              "إجمالي الديون: ${totalDebts.toStringAsFixed(0)}",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 10),
             Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text("الزبون")),
                      DataColumn(label: Text("الإجمالي")),
                      DataColumn(label: Text("المدفوع")),
                      DataColumn(label: Text("المتبقي")),
                    ],
                    rows: buildRows(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}