import 'package:worldshift_filters/models/item_filters_model.dart';
import 'package:worldshift_filters/screens/card_list.dart';
import 'package:worldshift_filters/screens/upload_info.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => FilterProvider(),
      child: const MyApp(),
    ),
  );
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
