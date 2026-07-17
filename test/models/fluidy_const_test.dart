import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fluidy_const', () {
    // ── Warna ─────────────────────────────────────────────────────────────────

    group('konstanta warna', () {
      test('lightBlue memiliki nilai hex yang benar', () {
        expect(lightBlue, const Color(0xFF03A9F4));
      });

      test('regularBlue memiliki nilai hex yang benar', () {
        expect(regularBlue, const Color(0xFF039BE5));
      });

      test('matteBlue memiliki nilai hex yang benar', () {
        expect(matteBlue, const Color(0xFF0288D1));
      });

      test('darkBlue memiliki nilai hex yang benar', () {
        expect(darkBlue, const Color(0xFF0277BD));
      });

      test('darkestBlue memiliki nilai hex yang benar', () {
        expect(darkestBlue, const Color(0xFF015798));
      });

      test('correctGreen memiliki nilai hex yang benar', () {
        expect(correctGreen, const Color(0xFF00C853));
      });

      test('darkRed memiliki nilai hex yang benar', () {
        expect(darkRed, const Color(0xFFB3261E));
      });

      test('appBackgroundColor adalah Colors.white', () {
        expect(appBackgroundColor, Colors.white);
      });

      test('warningColor memiliki nilai hex yang benar', () {
        expect(warningColor, const Color(0xFFFF9800));
      });

      test('dangerColor memiliki nilai hex yang benar', () {
        expect(dangerColor, const Color(0xFFD3302F));
      });

      test('urutan terang-gelap blue konsisten (lightBlue → darkestBlue)', () {
        // Nilai blue makin kecil = makin gelap
        final colors = [lightBlue, regularBlue, matteBlue, darkBlue, darkestBlue];
        for (int i = 0; i < colors.length - 1; i++) {
          // Komponen biru (blue channel) harus makin kecil atau sama
          expect(colors[i].blue, greaterThanOrEqualTo(colors[i + 1].blue));
        }
      });
    });

    // ── Enum ButtonStatus ─────────────────────────────────────────────────────

    group('enum ButtonStatus', () {
      test('memiliki 3 nilai: active, done, locked', () {
        expect(ButtonStatus.values.length, 3);
        expect(ButtonStatus.values, contains(ButtonStatus.active));
        expect(ButtonStatus.values, contains(ButtonStatus.done));
        expect(ButtonStatus.values, contains(ButtonStatus.locked));
      });

      test('nilai berbeda satu sama lain', () {
        expect(ButtonStatus.active, isNot(ButtonStatus.done));
        expect(ButtonStatus.active, isNot(ButtonStatus.locked));
        expect(ButtonStatus.done, isNot(ButtonStatus.locked));
      });
    });

    // ── Enum Bubbletail ───────────────────────────────────────────────────────

    group('enum Bubbletail', () {
      test('memiliki 3 nilai: right, left, none', () {
        expect(Bubbletail.values.length, 3);
        expect(Bubbletail.values, contains(Bubbletail.right));
        expect(Bubbletail.values, contains(Bubbletail.left));
        expect(Bubbletail.values, contains(Bubbletail.none));
      });
    });

    // ── Enum ChapterStatus ────────────────────────────────────────────────────

    group('enum ChapterStatus', () {
      test('memiliki 3 nilai: ongoing, done, locked', () {
        expect(ChapterStatus.values.length, 3);
        expect(ChapterStatus.values, contains(ChapterStatus.ongoing));
        expect(ChapterStatus.values, contains(ChapterStatus.done));
        expect(ChapterStatus.values, contains(ChapterStatus.locked));
      });
    });

    // ── Greyscale ColorFilter ─────────────────────────────────────────────────

    group('greyscale ColorFilter', () {
      test('greyscale adalah instance ColorFilter.matrix', () {
        expect(greyscale, isA<ColorFilter>());
      });
    });

    // ── BoxShadow ─────────────────────────────────────────────────────────────

    group('lightBoxShadow', () {
      test('blurRadius adalah 2', () {
        expect(lightBoxShadow.blurRadius, 2);
      });

      test('spreadRadius adalah 0', () {
        expect(lightBoxShadow.spreadRadius, 0);
      });

      test('offset adalah Offset(0, 3)', () {
        expect(lightBoxShadow.offset, const Offset(0, 3));
      });
    });
  });
}
