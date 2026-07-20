import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car_planner/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CarPlannerApp());
    await tester.pump();

    // Fără sqlite nativ disponibil în mediul de test, ecranul rămâne în
    // starea de încărcare — verificăm doar că pornirea aplicației nu
    // aruncă nicio eroare. Comportamentul complet e validat manual /
    // pe dispozitiv, unde sqflite funcționează nativ.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
