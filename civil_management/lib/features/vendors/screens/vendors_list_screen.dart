
import 'package:flutter/material.dart';

class VendorsListScreen extends StatelessWidget {
  const VendorsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendors')),
      body: const Center(child: Text('Vendors List')),
    );
  }
}
