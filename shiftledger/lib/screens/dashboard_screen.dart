import 'package:flutter/material.dart';
import '../navigations/app_drawer.dart';
import '../navigations/bottom_nav.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text("Dashboard")),
      bottomNavigationBar: const BottomNav(),
      body: const Center(
        child: Text(
          "Dashboard",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}