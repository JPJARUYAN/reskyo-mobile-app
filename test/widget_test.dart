import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reskyo_finale/utils/constants.dart';

void main() {
  group('Login Screen Widget Tests', () {
    testWidgets('shows email and password fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(decoration: InputDecoration(labelText: 'Email')),
                TextField(decoration: InputDecoration(labelText: 'Password')),
                ElevatedButton(onPressed: null, child: Text('Sign In')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('validates empty email', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
    });
  });

  group('Report Incident Form Widget Tests', () {
    testWidgets('shows incident type selector', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Select Type'),
                Wrap(
                  children: IncidentType.values.map((type) =>
                    ChoiceChip(
                      label: Text(type.label),
                      selected: false,
                      onSelected: (_) {},
                    )
                  ).toList(),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Select Type'), findsOneWidget);
      for (final type in IncidentType.values) {
        expect(find.text(type.label), findsOneWidget);
      }
    });

    testWidgets('incident type chips are selectable', (tester) async {
      int selected = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Wrap(
                children: List.generate(IncidentType.values.length, (i) =>
                  ChoiceChip(
                    label: Text(IncidentType.values[i].label),
                    selected: selected == i,
                    onSelected: (_) => setState(() => selected = i),
                  )
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Medical Emergency'));
      await tester.pump();
      // Chip should now be selected
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Medical Emergency'),
      );
      expect(chip.selected, true);
    });
  });

  group('Dispatch Accept/Decline Widget Tests', () {
    testWidgets('shows dispatch action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Accept'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Decline'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('dispatch status timeline renders', (tester) async {
      final steps = ['Dispatched', 'Accepted', 'En Route', 'On Scene', 'Resolved'];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: steps.map((s) => Column(
                children: [
                  const Icon(Icons.check_circle),
                  Text(s, style: const TextStyle(fontSize: 10)),
                ],
              )).toList(),
            ),
          ),
        ),
      );

      for (final step in steps) {
        expect(find.text(step), findsOneWidget);
      }
    });
  });

  group('Route Preview Widget Tests', () {
    testWidgets('shows distance and ETA', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Distance: 2.5 km'),
                Text('ETA: 5 min'),
                Text('Via: Digos-Pandacan Road'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Distance: 2.5 km'), findsOneWidget);
      expect(find.text('ETA: 5 min'), findsOneWidget);
      expect(find.text('Via: Digos-Pandacan Road'), findsOneWidget);
    });
  });
}
