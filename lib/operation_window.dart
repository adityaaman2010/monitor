import 'package:flutter/material.dart';

class OperationWindow extends StatefulWidget {
  const OperationWindow({Key? key}) : super(key: key);

  @override
  State<OperationWindow> createState() => _OperationWindowState();
}

class _OperationWindowState extends State<OperationWindow> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operational Window'),
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [Expanded(child: Container())],
        ),
      ),
    );
  }
}
