import 'package:fluidify_mobile/components/level_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluidyLevelButton', () {
    Widget buildWidget({
      required VoidCallback action,
      IconData icon = Icons.star_rounded,
      ButtonStatus state = ButtonStatus.locked,
      double size = 90,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: FluidyLevelButton(
              action: action,
              icon: icon,
              state: state,
              size: size,
            ),
          ),
        ),
      );
    }

    // ── Rendering ─────────────────────────────────────────────────────────────

    group('rendering', () {
      testWidgets('merender ikon yang diberikan', (tester) async {
        await tester.pumpWidget(
          buildWidget(action: () {}, icon: Icons.play_arrow_rounded),
        );

        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      });

      testWidgets('merender label "Simulasi" untuk ikon play_arrow', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            action: () {},
            icon: Icons.play_arrow_rounded,
            state: ButtonStatus.active,
          ),
        );

        expect(find.text('Simulasi'), findsOneWidget);
      });

      testWidgets('merender label "Eksplorasi" untuk ikon search', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            action: () {},
            icon: Icons.search_rounded,
            state: ButtonStatus.active,
          ),
        );

        expect(find.text('Eksplorasi'), findsOneWidget);
      });

      testWidgets('merender label "Peta Konsep" untuk ikon edit', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            action: () {},
            icon: Icons.edit_rounded,
            state: ButtonStatus.active,
          ),
        );

        expect(find.text('Peta Konsep'), findsOneWidget);
      });

      testWidgets('merender label "Umpan Balik" untuk ikon lightbulb', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            action: () {},
            icon: Icons.lightbulb,
            state: ButtonStatus.active,
          ),
        );

        expect(find.text('Umpan Balik'), findsOneWidget);
      });

      testWidgets('merender label "Kuis" untuk ikon question_mark', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            action: () {},
            icon: Icons.question_mark_rounded,
            state: ButtonStatus.active,
          ),
        );

        expect(find.text('Kuis'), findsOneWidget);
      });

      testWidgets('tidak merender label untuk ikon star (default)', (tester) async {
        await tester.pumpWidget(
          buildWidget(action: () {}, icon: Icons.star_rounded),
        );

        // Tidak ada label teks untuk ikon star
        expect(find.byType(Text), findsNothing);
      });
    });

    // ── Status dan Interaksi ──────────────────────────────────────────────────

    group('ButtonStatus.locked — tidak memanggil action', () {
      testWidgets('tap pada state locked tidak memanggil callback', (tester) async {
        bool wasCalled = false;

        await tester.pumpWidget(
          buildWidget(
            action: () => wasCalled = true,
            state: ButtonStatus.locked,
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();

        expect(wasCalled, isFalse);
      });
    });

    group('ButtonStatus.active — memanggil action', () {
      testWidgets('tap pada state active memanggil callback', (tester) async {
        bool wasCalled = false;

        await tester.pumpWidget(
          buildWidget(
            action: () => wasCalled = true,
            state: ButtonStatus.active,
          ),
        );

        // Simulasi tap-down dan tap-up
        final gesture = find.byType(GestureDetector).first;
        await tester.tapAt(tester.getCenter(gesture));
        await tester.pump();

        expect(wasCalled, isTrue);
      });
    });

    group('ButtonStatus.done — memanggil action', () {
      testWidgets('tap pada state done memanggil callback', (tester) async {
        bool wasCalled = false;

        await tester.pumpWidget(
          buildWidget(
            action: () => wasCalled = true,
            state: ButtonStatus.done,
          ),
        );

        final gesture = find.byType(GestureDetector).first;
        await tester.tapAt(tester.getCenter(gesture));
        await tester.pump();

        expect(wasCalled, isTrue);
      });
    });

    // ── Ukuran custom ─────────────────────────────────────────────────────────

    group('ukuran', () {
      testWidgets('menerima ukuran custom tanpa error', (tester) async {
        await tester.pumpWidget(
          buildWidget(action: () {}, size: 60),
        );

        // Widget merender tanpa overflow atau error
        expect(find.byType(FluidyLevelButton), findsOneWidget);
      });
    });

    // ── Animasi press ─────────────────────────────────────────────────────────

    group('animasi press', () {
      testWidgets('button aktif beranimasi saat ditekan', (tester) async {
        await tester.pumpWidget(
          buildWidget(action: () {}, state: ButtonStatus.active),
        );

        // Tekan dan tahan
        await tester.press(find.byType(GestureDetector).first);
        await tester.pump(const Duration(milliseconds: 50));

        // AnimatedPositioned ada di tree
        expect(find.byType(AnimatedPositioned), findsOneWidget);
      });
    });
  });
}
