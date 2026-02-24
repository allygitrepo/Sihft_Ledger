import 'package:flutter/material.dart';

class AppLoader extends StatelessWidget {
  final double size;

  const AppLoader({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/loader.gif',
        height: size,
        width: size,
      ),
    );
  }
}