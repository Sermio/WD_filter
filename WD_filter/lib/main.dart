import 'package:adv_basics/screens/card_list.dart';
import 'package:adv_basics/screens/upload_info.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card List App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CardListScreen(),
    );
  }
}
