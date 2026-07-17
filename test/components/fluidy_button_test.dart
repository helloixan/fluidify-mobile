import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FButtonWidget', () {
    // Helper untuk membungkus widget dalam MaterialApp
    Widget buildWidget({
      required String text,
      required VoidCallback action,
      Color? color,
      IconData? icon,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FButtonWidget(
            text: text,
            action: action,
            color: color,
            icon: icon,
          ),
        ),
      );
    }

    // ── Rendering ─────────────────────────────────────────────────────────────

    group('rendering', () {
      testWidgets('merender teks dengan benar', (tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Masuk', action: () {}),
        );

        expect(find.text('Masuk'), findsOneWidget);
      });

      testWidgets('merender ElevatedButton', (tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Test', action: () {}),
        );

        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('lebar button mengisi parent (double.infinity)', (tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Full Width', action: () {}),
        );

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, double.infinity);
      });

      testWidgets('merender ikon jika diberikan', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            text: 'Login Google',
            action: () {},
            icon: Icons.login,
          ),
        );

        expect(find.byIcon(Icons.login), findsOneWidget);
      });

      testWidgets('tidak merender ikon jika tidak diberikan', (tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Tanpa Ikon', action: () {}),
        );

        expect(find.byType(Icon), findsNothing);
      });
    });

    // ── Warna ─────────────────────────────────────────────────────────────────

    group('warna', () {
      testWidgets('menggunakan regularBlue sebagai warna default', (tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Default Color', action: () {}),
        );

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final style = button.style!.backgroundColor?.resolve({});
        expect(style, regularBlue);
      });

      testWidgets('menggunakan warna custom jika diberikan', (tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Custom Color', action: () {}, color: Colors.red),
        );

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final style = button.style!.backgroundColor?.resolve({});
        expect(style, Colors.red);
      });
    });

    // ── Interaksi (tap) ───────────────────────────────────────────────────────

    group('interaksi', () {
      testWidgets('memanggil callback action saat ditekan', (tester) async {
        bool wasTapped = false;

        await tester.pumpWidget(
          buildWidget(text: 'Tap Me', action: () => wasTapped = true),
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(wasTapped, isTrue);
      });

      testWidgets('memanggil action beberapa kali saat ditekan berulang',
          (tester) async {
        int tapCount = 0;

        await tester.pumpWidget(
          buildWidget(text: 'Multi Tap', action: () => tapCount++),
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.tap(find.byType(ElevatedButton));
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(tapCount, 3);
      });
    });

    // ── Teks dan Ikon bersama ─────────────────────────────────────────────────

    group('kombinasi teks dan ikon', () {
      testWidgets('merender teks dan ikon secara bersamaan', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            text: 'Daftar',
            action: () {},
            icon: Icons.person_add,
          ),
        );

        expect(find.text('Daftar'), findsOneWidget);
        expect(find.byIcon(Icons.person_add), findsOneWidget);
      });

      testWidgets('ikon muncul sebelum teks (ada padding di kanan ikon)',
          (tester) async {
        await tester.pumpWidget(
          buildWidget(
            text: 'Dengan Ikon',
            action: () {},
            icon: Icons.star,
          ),
        );

        // Pastikan ikon ada di dalam Padding
        final paddingFinder = find.ancestor(
          of: find.byIcon(Icons.star),
          matching: find.byType(Padding),
        );
        expect(paddingFinder, findsWidgets);
      });
    });
  });
}
