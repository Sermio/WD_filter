import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:worldshift_assistant/models/item_filters_model.dart';
import 'package:worldshift_assistant/screens/home_shell.dart';

void main() {
  testWidgets('HomeShell muestra navegación inferior', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FilterProvider(),
        child: const MaterialApp(
          home: HomeShell(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
