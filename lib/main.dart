import 'package:flutter/material.dart';

void main() {
  runApp(const InternManagementApp());
}

class InternManagementApp extends StatelessWidget {
  const InternManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Intern Management System'))),
    );
  }
}
