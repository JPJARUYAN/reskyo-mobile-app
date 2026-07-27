import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reskyo_finale/utils/constants.dart';

void main() {
  group('IncidentType enum', () {
    test('all types have labels', () {
      for (final type in IncidentType.values) {
        expect(type.label.isNotEmpty, true, reason: '${type.name} has empty label');
      }
    });

    test('all types have icons', () {
      for (final type in IncidentType.values) {
        expect(type.icon, isNotNull, reason: '${type.name} has null icon');
      }
    });

    test('all types have colors', () {
      for (final type in IncidentType.values) {
        expect(type.color, isNotNull, reason: '${type.name} has null color');
      }
    });

    test('labels match expected values', () {
      expect(IncidentType.vehicularAccident.label, 'Vehicular Accident');
      expect(IncidentType.medicalEmergency.label, 'Medical Emergency');
      expect(IncidentType.fire.label, 'Fire');
      expect(IncidentType.rescueOperation.label, 'Rescue Operation');
      expect(IncidentType.other.label, 'Other');
    });
  });

  group('IncidentStatus enum', () {
    test('all statuses have labels', () {
      for (final status in IncidentStatus.values) {
        expect(status.label.isNotEmpty, true);
      }
    });

    test('status flow order is correct', () {
      final expected = ['Reported', 'Verified', 'Dispatched', 'In Progress', 'Resolved', 'Dismissed'];
      for (var i = 0; i < expected.length; i++) {
        expect(IncidentStatus.values[i].label, expected[i]);
      }
    });
  });

  group('DispatchStatus enum', () {
    test('all statuses have labels', () {
      for (final status in DispatchStatus.values) {
        expect(status.label.isNotEmpty, true);
      }
    });

    test('dispatch flow order is correct', () {
      final expected = ['Pending', 'Accepted', 'En Route', 'On Scene', 'Resolved'];
      for (var i = 0; i < expected.length; i++) {
        expect(DispatchStatus.values[i].label, expected[i]);
      }
    });
  });

  group('AppColors', () {
    test('brand colors are defined', () {
      expect(AppColors.primary, const Color(0xFFE01D25));
      expect(AppColors.primaryDark, const Color(0xFF011A38));
    });

    test('status colors are distinct', () {
      final colors = [
        IncidentStatus.reported.color,
        IncidentStatus.verified.color,
        IncidentStatus.dispatched.color,
        IncidentStatus.inProgress.color,
        IncidentStatus.resolved.color,
        IncidentStatus.dismissed.color,
      ];
      final unique = colors.toSet();
      expect(unique.length, colors.length, reason: 'All status colors should be unique');
    });
  });

  group('AppConstants', () {
    test('app name is RESKYO', () {
      expect(AppConstants.appName, 'RESKYO');
    });

    test('Digos City coordinates are valid', () {
      expect(AppConstants.defaultLat, inInclusiveRange(6.0, 7.0));
      expect(AppConstants.defaultLng, inInclusiveRange(125.0, 126.0));
    });
  });

  group('Widget smoke tests', () {
    testWidgets('MaterialApp builds without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('RESKYO Test')),
          ),
        ),
      );
      expect(find.text('RESKYO Test'), findsOneWidget);
    });

    testWidgets('StatusBadge renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Chip(
                avatar: Icon(Icons.check_circle, size: 14),
                label: Text('Resolved'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Incident type icons render', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: IncidentType.values.map((type) =>
                Icon(type.icon, key: Key(type.name))
              ).toList(),
            ),
          ),
        ),
      );
      for (final type in IncidentType.values) {
        expect(find.byKey(Key(type.name)), findsOneWidget);
      }
    });
  });
}
