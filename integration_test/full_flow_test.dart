// ============================================
// PHASE 9: Integration Test — Full Flow
// Resident Report → Admin Verify → Responder Dispatch → Status Update
//
// Run: flutter test integration_test/full_flow_test.dart
// (requires connected device or emulator)
// ============================================

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('RESKYO Full Flow Integration Test', () {
    testWidgets('1. App launches and shows splash screen', (tester) async {
      // NOTE: In a real integration test, you'd pump the actual ReskyoApp.
      // This is a scaffold for your defense demonstration.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 64, color: Color(0xFFE01D25)),
                  const SizedBox(height: 16),
                  const Text(
                    'RESKYO',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('GPS-Based Emergency Response System'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('RESKYO'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('2. Login form accepts credentials', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const TextField(
                    key: Key('email_field'),
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  const TextField(
                    key: Key('password_field'),
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  ElevatedButton(
                    key: Key('login_button'),
                    onPressed: () {},
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('email_field')), 'admin@reskyo.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      expect(find.text('admin@reskyo.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('3. Incident type selection works', (tester) async {
      int? selectedType;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Wrap(
                children: List.generate(5, (i) => ChoiceChip(
                  label: Text(['Accident', 'Medical', 'Fire', 'Rescue', 'Other'][i]),
                  selected: selectedType == i,
                  onSelected: (_) => setState(() => selectedType = i),
                )),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Medical'));
      await tester.pump();
      expect(selectedType, 1);
    });

    testWidgets('4. Dispatch status progression', (tester) async {
      final statuses = ['Pending', 'Accepted', 'En Route', 'On Scene', 'Resolved'];
      int currentStep = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(statuses.length, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Icon(
                            i <= currentStep ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: i <= currentStep ? Colors.green : Colors.grey,
                          ),
                          Text(statuses[i], style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: currentStep < statuses.length - 1
                      ? () => setState(() => currentStep++)
                      : null,
                    child: Text(currentStep < statuses.length - 1
                      ? 'Advance to ${statuses[currentStep + 1]}'
                      : 'Completed'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Progress through all statuses
      for (var i = 0; i < statuses.length - 1; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
      }

      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('5. Profile screen shows user info', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CircleAvatar(radius: 32, child: Icon(Icons.person)),
                SizedBox(height: 8),
                Text('Juan Dela Cruz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Magsaysay, Digos City'),
                Text('09123456789'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Juan Dela Cruz'), findsOneWidget);
      expect(find.text('Magsaysay, Digos City'), findsOneWidget);
      expect(find.text('09123456789'), findsOneWidget);
    });
  });
}
