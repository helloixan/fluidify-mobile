import 'package:fluidify_mobile/components/confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FConfirmationDialog', () {
    // Helper: tampilkan dialog melalui showDialog agar punya Navigator context
    Future<void> showDialog_({
      required WidgetTester tester,
      String? title,
      required String content,
      String? cancelButtonText,
      String? confirmButtonText,
      required VoidCallback action,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => FConfirmationDialog(
                      title: title,
                      content: content,
                      cancelButtonText: cancelButtonText,
                      confirmButtonText: confirmButtonText,
                      action: action,
                    ),
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();
    }

    // ── Rendering ─────────────────────────────────────────────────────────────

    group('rendering', () {
      testWidgets('menampilkan judul default jika tidak diberikan', (tester) async {
        await showDialog_(
          tester: tester,
          content: 'Apakah kamu yakin?',
          action: () {},
        );

        expect(find.text('Konfirmasi Penghapusan'), findsOneWidget);
      });

      testWidgets('menampilkan judul custom jika diberikan', (tester) async {
        await showDialog_(
          tester: tester,
          title: 'Hapus Bab',
          content: 'Data akan hilang permanen.',
          action: () {},
        );

        expect(find.text('Hapus Bab'), findsOneWidget);
      });

      testWidgets('menampilkan konten/pesan dialog', (tester) async {
        await showDialog_(
          tester: tester,
          content: 'Yakin ingin menghapus data ini?',
          action: () {},
        );

        expect(find.text('Yakin ingin menghapus data ini?'), findsOneWidget);
      });

      testWidgets('menampilkan tombol batal dengan teks default "Batal"',
          (tester) async {
        await showDialog_(
          tester: tester,
          content: 'Content test',
          action: () {},
        );

        expect(find.text('Batal'), findsOneWidget);
      });

      testWidgets('menampilkan tombol konfirmasi dengan teks default "Yakin"',
          (tester) async {
        await showDialog_(
          tester: tester,
          content: 'Content test',
          action: () {},
        );

        expect(find.text('Yakin'), findsOneWidget);
      });

      testWidgets('menampilkan teks tombol batal custom', (tester) async {
        await showDialog_(
          tester: tester,
          content: 'Content',
          cancelButtonText: 'Tidak, Kembali',
          action: () {},
        );

        expect(find.text('Tidak, Kembali'), findsOneWidget);
      });

      testWidgets('menampilkan teks tombol konfirmasi custom', (tester) async {
        await showDialog_(
          tester: tester,
          content: 'Content',
          confirmButtonText: 'Ya, Hapus!',
          action: () {},
        );

        expect(find.text('Ya, Hapus!'), findsOneWidget);
      });

      testWidgets('merender AlertDialog', (tester) async {
        await showDialog_(
          tester: tester,
          content: 'Test AlertDialog',
          action: () {},
        );

        expect(find.byType(AlertDialog), findsOneWidget);
      });
    });

    // ── Interaksi ─────────────────────────────────────────────────────────────

    group('interaksi', () {
      testWidgets('tombol batal menutup dialog', (tester) async {
        await showDialog_(
          tester: tester,
          content: 'Apakah kamu yakin?',
          action: () {},
        );

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('tombol konfirmasi memanggil action callback', (tester) async {
        bool confirmed = false;

        await showDialog_(
          tester: tester,
          content: 'Hapus item?',
          action: () => confirmed = true,
        );

        await tester.tap(find.text('Yakin'));
        await tester.pump();

        expect(confirmed, isTrue);
      });

      testWidgets('tombol batal TIDAK memanggil action callback', (tester) async {
        bool confirmed = false;

        await showDialog_(
          tester: tester,
          content: 'Hapus item?',
          action: () => confirmed = true,
        );

        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(confirmed, isFalse);
      });
    });
  });
}
