import 'package:flutter/material.dart';
import 'package:monitor/log_view.dart';

import 'login.dart';
import 'port_config.dart';
import 'das_setting.dart';
import 'operation_window.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DATA ACQUISION SYSTEM',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/login': (context) => const Login(),
        '/': (context) => const Login(),
        '/port_config': (context) => const PortConfig(),
        '/das_setting': (context) => const DasSetting(),
        '/operations': (context) => const OperationWindow(),
        '/log_view': (context) => const LogView(),
      },
    );
  }
}
