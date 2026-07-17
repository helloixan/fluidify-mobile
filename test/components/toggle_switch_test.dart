import 'package:fluidify_mobile/components/toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluidifyToggleSwitch', () {
    Widget buildWidget({
      String leftText = 'Kiri',
      String rightText = 'Kanan',
      required Function(bool) onChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FluidifyToggleSwitch(
            leftText: leftText,
            rightText: rightText,
            onChanged: onChanged,
          ),
        ),
      );
    }

    // ── Rendering ─────────────────────────────────────────────────────────────

    group('rendering', () {
      testWidgets('menampilkan teks kiri dan kanan', (tester) async {
        await tester.pumpWidget(
          buildWidget(leftText: 'Siswa', rightText: 'Guru', onChanged: (_) {}),
        );

        expect(find.text('Siswa'), findsOneWidget);
        expect(find.text('Guru'), findsOneWidget);
      });

      testWidgets('merender dua GestureDetector (kiri & kanan)', (tester) async {
        await tester.pumpWidget(
          buildWidget(onChanged: (_) {}),
        );

        expect(find.byType(GestureDetector), findsNWidgets(2));
      });
    });

    // ── State awal ────────────────────────────────────────────────────────────

    group('state awal', () {
      testWidgets('state awal adalah kiri terpilih (_isLeftSelected = true)',
          (tester) async {
        bool? lastValue;

        await tester.pumpWidget(
          buildWidget(
            leftText: 'Siswa',
            rightText: 'Guru',
            onChanged: (v) => lastValue = v,
          ),
        );

        // Tap kanan untuk memicu perubahan, lalu balik ke kiri
        await tester.tap(find.text('Guru'));
        await tester.pump();

        expect(lastValue, isFalse); // berubah ke kanan
      });
    });

    // ── Interaksi ─────────────────────────────────────────────────────────────

    group('interaksi toggle', () {
      testWidgets('mengganti ke kanan saat tap kanan', (tester) async {
        bool? lastValue;

        await tester.pumpWidget(
          buildWidget(
            leftText: 'Kiri',
            rightText: 'Kanan',
            onChanged: (v) => lastValue = v,
          ),
        );

        await tester.tap(find.text('Kanan'));
        await tester.pump();

        expect(lastValue, isFalse); // isLeftSelected = false
      });

      testWidgets('mengganti ke kiri saat tap kiri setelah memilih kanan',
          (tester) async {
        bool? lastValue;

        await tester.pumpWidget(
          buildWidget(
            leftText: 'Kiri',
            rightText: 'Kanan',
            onChanged: (v) => lastValue = v,
          ),
        );

        // Pindah ke kanan dulu
        await tester.tap(find.text('Kanan'));
        await tester.pump();

        // Pindah kembali ke kiri
        await tester.tap(find.text('Kiri'));
        await tester.pump();

        expect(lastValue, isTrue); // isLeftSelected = true
      });

      testWidgets('tidak memanggil onChanged jika tap pada pilihan yang sudah aktif',
          (tester) async {
        int callCount = 0;

        await tester.pumpWidget(
          buildWidget(
            leftText: 'Kiri',
            rightText: 'Kanan',
            onChanged: (_) => callCount++,
          ),
        );

        // Tap kiri berkali-kali (sudah aktif dari awal)
        await tester.tap(find.text('Kiri'));
        await tester.tap(find.text('Kiri'));
        await tester.pump();

        // onChanged tidak boleh terpanggil karena sudah di posisi kiri
        expect(callCount, 0);
      });

      testWidgets('animasi toggle berjalan tanpa error', (tester) async {
        await tester.pumpWidget(
          buildWidget(leftText: 'A', rightText: 'B', onChanged: (_) {}),
        );

        await tester.tap(find.text('B'));
        await tester.pumpAndSettle(); // tunggu AnimatedAlign selesai

        expect(find.text('B'), findsOneWidget);
      });

      testWidgets('toggle bolak-balik beberapa kali', (tester) async {
        final values = <bool>[];

        await tester.pumpWidget(
          buildWidget(
            leftText: 'X',
            rightText: 'Y',
            onChanged: (v) => values.add(v),
          ),
        );

        await tester.tap(find.text('Y'));
        await tester.pump();
        await tester.tap(find.text('X'));
        await tester.pump();
        await tester.tap(find.text('Y'));
        await tester.pump();

        expect(values, [false, true, false]);
      });
    });
  });
}
