
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final screens = [
    Center(child: Text("المقاوته")),
    Center(child: Text("الزبائن")),
    Center(child: Text("البيع")),
    Center(child: Text("التقارير")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("محرّج"),
      ),

      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.store), label: "المقاوته"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "الزبائن"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: "البيع"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "تقارير"),
        ],
      ),
    );
  }
}

