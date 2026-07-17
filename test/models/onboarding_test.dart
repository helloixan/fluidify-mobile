import 'package:flutter_test/flutter_test.dart';
import 'package:fluidify_mobile/models/onboarding.dart';

void main() {
  group('Onboarding Model', () {
    // ── Constructor ──────────────────────────────────────────────────────────

    group('constructor', () {
      test('membuat instance dengan semua field yang benar', () {
        final onboarding = Onboarding(
          title: 'Selamat Datang',
          description: 'Ini adalah deskripsi onboarding',
          imageSrc: 'assets/img/onboarding1.png',
        );

        expect(onboarding.title, 'Selamat Datang');
        expect(onboarding.description, 'Ini adalah deskripsi onboarding');
        expect(onboarding.imageSrc, 'assets/img/onboarding1.png');
      });

      test('setiap field bersifat required', () {
        // Memastikan tidak ada nilai null pada field wajib
        final onboarding = Onboarding(
          title: 'Judul',
          description: 'Deskripsi',
          imageSrc: 'img.png',
        );

        expect(onboarding.title, isNotNull);
        expect(onboarding.description, isNotNull);
        expect(onboarding.imageSrc, isNotNull);
      });

      test('title tidak boleh kosong saat digunakan', () {
        final onboarding = Onboarding(
          title: 'Belajar Fisika',
          description: 'Penjelasan singkat',
          imageSrc: 'assets/img/slide1.png',
        );

        expect(onboarding.title, isNotEmpty);
      });

      test('imageSrc menyimpan path asset dengan benar', () {
        final onboarding = Onboarding(
          title: 'Slide 2',
          description: 'Deskripsi slide 2',
          imageSrc: 'assets/img/onboarding2.png',
        );

        expect(onboarding.imageSrc, contains('assets/'));
      });
    });

    // ── Beberapa instance (representasi daftar slide) ─────────────────────────

    group('multiple instances', () {
      test('membuat beberapa slide onboarding berbeda', () {
        final slides = [
          Onboarding(
            title: 'Belajar Interaktif',
            description: 'Nikmati pengalaman belajar yang menyenangkan',
            imageSrc: 'assets/img/slide1.png',
          ),
          Onboarding(
            title: 'Latihan Soal',
            description: 'Uji kemampuan dengan soal-soal pilihan',
            imageSrc: 'assets/img/slide2.png',
          ),
          Onboarding(
            title: 'Pantau Progres',
            description: 'Lihat perkembangan belajar kamu',
            imageSrc: 'assets/img/slide3.png',
          ),
        ];

        expect(slides.length, 3);
        expect(slides[0].title, 'Belajar Interaktif');
        expect(slides[1].title, 'Latihan Soal');
        expect(slides[2].title, 'Pantau Progres');
      });

      test('setiap instance memiliki data independen', () {
        final slide1 = Onboarding(
          title: 'Judul A',
          description: 'Desc A',
          imageSrc: 'imgA.png',
        );
        final slide2 = Onboarding(
          title: 'Judul B',
          description: 'Desc B',
          imageSrc: 'imgB.png',
        );

        expect(slide1.title, isNot(equals(slide2.title)));
        expect(slide1.imageSrc, isNot(equals(slide2.imageSrc)));
      });
    });

    // ── Edge cases ────────────────────────────────────────────────────────────

    group('edge cases', () {
      test('menerima teks deskripsi yang panjang', () {
        final longDesc = 'Deskripsi panjang ' * 50;
        final onboarding = Onboarding(
          title: 'Test',
          description: longDesc,
          imageSrc: 'img.png',
        );

        expect(onboarding.description, longDesc);
      });

      test('menerima path imageSrc yang kompleks', () {
        const path = 'assets/images/onboarding/step_1_illustration.png';
        final onboarding = Onboarding(
          title: 'Test',
          description: 'Desc',
          imageSrc: path,
        );

        expect(onboarding.imageSrc, path);
      });
    });
  });
}
