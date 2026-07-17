import 'package:flutter_test/flutter_test.dart';
import 'package:fluidify_mobile/models/chat_messages.dart';

void main() {
  group('ChatMessage Model', () {
    // ── Constructor ──────────────────────────────────────────────────────────

    group('constructor', () {
      test('membuat instance dengan semua field yang diberikan', () {
        final message = ChatMessage(
          text: 'Halo, ini pesan test',
          isBot: false,
          imageRef: 'assets/img/test.png',
        );

        expect(message.text, 'Halo, ini pesan test');
        expect(message.isBot, false);
        expect(message.imageRef, 'assets/img/test.png');
      });

      test('membuat instance tanpa imageRef (nullable)', () {
        final message = ChatMessage(
          text: 'Pesan tanpa gambar',
          isBot: true,
        );

        expect(message.text, 'Pesan tanpa gambar');
        expect(message.isBot, true);
        expect(message.imageRef, isNull);
      });

      test('membuat pesan bot', () {
        final botMessage = ChatMessage(text: 'Saya adalah bot', isBot: true);
        expect(botMessage.isBot, isTrue);
      });

      test('membuat pesan pengguna', () {
        final userMessage =
            ChatMessage(text: 'Saya adalah pengguna', isBot: false);
        expect(userMessage.isBot, isFalse);
      });
    });

    // ── toMap ────────────────────────────────────────────────────────────────

    group('toMap()', () {
      test('mengkonversi semua field ke Map dengan benar', () {
        final message = ChatMessage(
          text: 'Test toMap',
          isBot: true,
          imageRef: 'ref/image.png',
        );

        final map = message.toMap();

        expect(map['text'], 'Test toMap');
        expect(map['isBot'], true);
        expect(map['imageRef'], 'ref/image.png');
      });

      test('imageRef bernilai null ketika tidak diberikan', () {
        final message = ChatMessage(text: 'Tanpa gambar', isBot: false);
        final map = message.toMap();

        expect(map['imageRef'], isNull);
      });

      test('Map mengandung tepat 3 key', () {
        final message = ChatMessage(text: 'Test', isBot: true);
        final map = message.toMap();

        expect(map.keys, containsAll(['text', 'isBot', 'imageRef']));
        expect(map.length, 3);
      });

      test('tipe data dalam Map sudah sesuai', () {
        final message =
            ChatMessage(text: 'Cek tipe', isBot: false, imageRef: 'img.png');
        final map = message.toMap();

        expect(map['text'], isA<String>());
        expect(map['isBot'], isA<bool>());
        expect(map['imageRef'], isA<String>());
      });
    });

    // ── fromMap ──────────────────────────────────────────────────────────────

    group('fromMap()', () {
      test('membuat instance dari Map yang lengkap', () {
        final map = {
          'text': 'Pesan dari map',
          'isBot': true,
          'imageRef': 'assets/test.png',
        };

        final message = ChatMessage.fromMap(map);

        expect(message.text, 'Pesan dari map');
        expect(message.isBot, true);
        expect(message.imageRef, 'assets/test.png');
      });

      test('menggunakan nilai default saat key "text" tidak ada di Map', () {
        final map = {'isBot': false};
        final message = ChatMessage.fromMap(map);

        expect(message.text, '');
      });

      test('menggunakan nilai default saat key "isBot" tidak ada di Map', () {
        final map = {'text': 'Ada teks'};
        final message = ChatMessage.fromMap(map);

        expect(message.isBot, true); // default dari fromMap: map['isBot'] ?? true
      });

      test('imageRef null jika tidak ada di Map', () {
        final map = {'text': 'Test', 'isBot': false};
        final message = ChatMessage.fromMap(map);

        expect(message.imageRef, isNull);
      });

      test('imageRef null jika eksplisit null di Map', () {
        final map = {
          'text': 'Test',
          'isBot': true,
          'imageRef': null,
        };
        final message = ChatMessage.fromMap(map);

        expect(message.imageRef, isNull);
      });
    });

    // ── Siklus toMap → fromMap ────────────────────────────────────────────────

    group('round-trip toMap() → fromMap()', () {
      test('menjaga konsistensi data (dengan imageRef)', () {
        final original = ChatMessage(
          text: 'Pesan round-trip',
          isBot: false,
          imageRef: 'assets/img/fluidy.png',
        );

        final restored = ChatMessage.fromMap(original.toMap());

        expect(restored.text, original.text);
        expect(restored.isBot, original.isBot);
        expect(restored.imageRef, original.imageRef);
      });

      test('menjaga konsistensi data (tanpa imageRef)', () {
        final original = ChatMessage(text: 'Tanpa gambar', isBot: true);
        final restored = ChatMessage.fromMap(original.toMap());

        expect(restored.text, original.text);
        expect(restored.isBot, original.isBot);
        expect(restored.imageRef, isNull);
      });

      test('menangani teks yang panjang dengan benar', () {
        final longText = 'A' * 1000;
        final original = ChatMessage(text: longText, isBot: true);
        final restored = ChatMessage.fromMap(original.toMap());

        expect(restored.text, longText);
      });

      test('menangani teks kosong', () {
        final original = ChatMessage(text: '', isBot: false);
        final restored = ChatMessage.fromMap(original.toMap());

        expect(restored.text, '');
        expect(restored.isBot, isFalse);
      });

      test('menangani karakter khusus dalam teks', () {
        const specialText = r'Rumus: $E = mc^2$ & <b>tebal</b>';
        final original = ChatMessage(text: specialText, isBot: true);
        final restored = ChatMessage.fromMap(original.toMap());

        expect(restored.text, specialText);
      });
    });
  });
}
