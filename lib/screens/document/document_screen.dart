import 'package:document_management_app/screens/header/header_screen.dart';
import 'package:document_management_app/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  int selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const HeaderScreen(),
      ),
      bottomNavigationBar: CustomBottomBar(selectedIndex: selectedIndex),
    );
  }
}
