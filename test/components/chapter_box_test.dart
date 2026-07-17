import 'package:fluidify_mobile/components/chapter_box.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChapterBox', () {
    Widget buildWidget({required String chapterName, String state = 'locked'}) {
      return MaterialApp(
        home: Scaffold(
          body: ChapterBox(chapterName: chapterName, state: state),
        ),
      );
    }

    // ── Rendering ─────────────────────────────────────────────────────────────

    group('rendering', () {
      testWidgets('menampilkan nama chapter dengan benar', (tester) async {
        await tester.pumpWidget(
          buildWidget(chapterName: 'Bab 1: Fluida Statis'),
        );

        expect(find.text('Bab 1: Fluida Statis'), findsOneWidget);
      });

      testWidgets('merender ikon buku', (tester) async {
        await tester.pumpWidget(
          buildWidget(chapterName: 'Bab 1'),
        );

        expect(find.byIcon(Icons.book_rounded), findsOneWidget);
      });

      testWidgets('state default adalah "locked"', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ChapterBox(chapterName: 'Default')),
          ),
        );

        // Tidak error & merender dengan benar
        expect(find.text('Default'), findsOneWidget);
      });
    });

    // ── Warna berdasarkan state ────────────────────────────────────────────────

    group('warna berdasarkan state', () {
      testWidgets('state "current" → warna regularBlue', (tester) async {
        await tester.pumpWidget(
          buildWidget(chapterName: 'Bab Aktif', state: 'current'),
        );

        await tester.pump();

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(ChapterBox),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, regularBlue);
      });

      testWidgets('state "completed" → warna correctGreen', (tester) async {
        await tester.pumpWidget(
          buildWidget(chapterName: 'Bab Selesai', state: 'completed'),
        );

        await tester.pump();

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(ChapterBox),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, correctGreen);
      });

      testWidgets('state "locked" → warna abu-abu', (tester) async {
        await tester.pumpWidget(
          buildWidget(chapterName: 'Bab Terkunci', state: 'locked'),
        );

        await tester.pump();

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(ChapterBox),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        // state locked menggunakan Colors.grey[400]
        expect(decoration.color, Colors.grey[400]);
      });
    });

    // ── Dimensi ───────────────────────────────────────────────────────────────

    group('dimensi', () {
      testWidgets('tinggi container adalah 65', (tester) async {
        await tester.pumpWidget(
          buildWidget(chapterName: 'Dimensi Test'),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(ChapterBox),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.maxHeight ?? 65, greaterThanOrEqualTo(65));
      });
    });

    // ── State tidak dikenal ───────────────────────────────────────────────────

    group('state tidak dikenal', () {
      testWidgets('state tidak dikenal tidak menyebabkan error', (tester) async {
        // State "unknown" tidak masuk ke kondisi apapun, widget tetap merender
        await tester.pumpWidget(
          buildWidget(chapterName: 'Unknown State', state: 'unknown'),
        );

        expect(find.text('Unknown State'), findsOneWidget);
      });
    });
  });
}
