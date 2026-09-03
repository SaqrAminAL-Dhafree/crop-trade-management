
import 'package:flutter/material.dart';

// صفحات سننشئها لاحقًا
import 'search_day_screen.dart';
import 'today_debts_screen.dart';
import 'daily_report_screen.dart';

class HistoryHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("عملياتي"),
        centerTitle: true,
      ),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔍 البحث في يوم
            _buildCard(
              context,
              title: "البحث في يوم محدد",
              subtitle: "استرجاع بيانات أي يوم سابق",
              icon: Icons.search,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchDayScreen(),
                  ),
                );
              },
            ),

            SizedBox(height: 15),

            // 💰 ديون اليوم
            _buildCard(
              context,
              title: "ديون اليوم",
              subtitle: "عرض الديون الحالية",
              icon: Icons.attach_money,
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TodayDebtsScreen(),
                  ),
                );
              },
            ),

            SizedBox(height: 15),

            // 📊 تقرير اليوم
            _buildCard(
              context,
              title: "تقرير اليوم",
              subtitle: "تقرير شامل للمقوت والزبائن",
              icon: Icons.bar_chart,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DailyReportScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}

