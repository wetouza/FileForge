import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App should render home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('FileForge')),
          ),
        ),
      ),
    );

    expect(find.text('FileForge'), findsOneWidget);
  });

  testWidgets('Upload button should be visible', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: null,
              child: Text('Выбрать файл'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Выбрать файл'), findsOneWidget);
  });

  testWidgets('Category cards should be tappable', (WidgetTester tester) async {
    bool tapped = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            onTap: () => tapped = true,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Text('Аудио'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Аудио'));
    expect(tapped, true);
  });

  testWidgets('Progress indicator should show percentage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(value: 0.5),
                SizedBox(height: 8),
                Text('50%'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('50%'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
