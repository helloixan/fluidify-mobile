import 'package:fluidify_mobile/components/fluidy_outlinebutton.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FOutlinedButton', () {
    Widget buildWidget({
      required String text,
      required VoidCallback action,
      IconData? icon,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FOutlinedButton(text: text, action: action, icon: icon),
        ),
      );
    }

    // ── Rendering ─────────────────────────────────────────────────────────────

    group('rendering', () {
      testWidgets('merender teks dengan benar', (tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Daftar Sekarang', action: () {}),
        );

        expect(find.text('Daftar Sekarang'), findsOneWidget);
      });

      testWidgets('merender OutlinedButton', (tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Test', action: () {}),
        );

        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('lebar button mengisi parent', (tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Full', action: () {}),
        );

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, double.infinity);
      });

      testWidgets('merender ikon jika diberikan', (tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Dengan Icon', action: () {}, icon: Icons.school),
        );

        expect(find.byIcon(Icons.school), findsOneWidget);
      });

      testWidgets('tidak merender ikon jika tidak diberikan', (tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Tanpa Icon', action: () {}),
        );

        expect(find.byType(Icon), findsNothing);
      });
    });

    // ── Style (border & warna) ────────────────────────────────────────────────

    group('style', () {
      testWidgets('menggunakan regularBlue sebagai warna border dan teks',
          (tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Style Test', action: () {}),
        );

        final button =
            tester.widget<OutlinedButton>(find.byType(OutlinedButton));
        final borderSide =
            (button.style!.side?.resolve({}) as BorderSide);
        expect(borderSide.color, regularBlue);
        expect(borderSide.width, 2);
      });
    });

    // ── Interaksi ─────────────────────────────────────────────────────────────

    group('interaksi', () {
      testWidgets('memanggil callback saat ditekan', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildWidget(text: 'Tap', action: () => tapped = true),
        );

        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('menghitung jumlah tap dengan benar', (tester) async {
        int count = 0;

        await tester.pumpWidget(
          buildWidget(text: 'Count', action: () => count++),
        );

        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byType(OutlinedButton));
        }
        await tester.pump();

        expect(count, 5);
      });
    });
  });
}
