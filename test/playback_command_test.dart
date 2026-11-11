import 'package:flutter_test/flutter_test.dart';
import 'package:youtubealexa/playback_command.dart';

void main() {
  group('PlaybackCommand.fromPhrase', () {
    test('recognizes Portuguese playback commands independent of accents', () {
      expect(
        PlaybackCommand.fromPhrase('Próxima música'),
        PlaybackCommand.next,
      );
      expect(
        PlaybackCommand.fromPhrase('voltar música anterior'),
        PlaybackCommand.previous,
      );
      expect(
        PlaybackCommand.fromPhrase('pausar a música'),
        PlaybackCommand.pause,
      );
      expect(PlaybackCommand.fromPhrase('Toque'), PlaybackCommand.play);
    });

    test('recognizes natural volume commands', () {
      expect(
        PlaybackCommand.fromPhrase('aumenta o volume'),
        PlaybackCommand.volumeUp,
      );
      expect(
        PlaybackCommand.fromPhrase('diminuir o volume'),
        PlaybackCommand.volumeDown,
      );
    });

    test('recognizes Friday followed by a playback command', () {
      expect(
        PlaybackCommand.fromWakePhrase('Friday, próxima música'),
        PlaybackCommand.next,
      );
      expect(
        PlaybackCommand.fromWakePhrase('FRIDAY pausar'),
        PlaybackCommand.pause,
      );
      expect(PlaybackCommand.containsWakeWord('Ei, Friday'), isTrue);
      expect(PlaybackCommand.containsWakeWord('Fridayzinha'), isFalse);
      expect(PlaybackCommand.fromWakePhrase('Friday'), isNull);
    });

    test('recognizes English and Portuguese wake word pronunciations', () {
      for (final wakePhrase in ['fraidei', 'sexta-feira', 'sexta feira']) {
        expect(
          PlaybackCommand.fromWakePhrase('$wakePhrase, próxima música'),
          PlaybackCommand.next,
        );
        expect(PlaybackCommand.containsWakeWord('Ei, $wakePhrase'), isTrue);
      }

      expect(PlaybackCommand.containsWakeWord('sextavocês'), isFalse);
    });

    test('returns null for unrelated speech', () {
      expect(PlaybackCommand.fromPhrase('bom dia'), isNull);
      expect(PlaybackCommand.fromPhrase('   '), isNull);
    });
  });
}
