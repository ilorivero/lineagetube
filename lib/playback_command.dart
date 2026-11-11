enum PlaybackCommand {
  play,
  pause,
  next,
  previous,
  volumeUp,
  volumeDown;

  static final RegExp _wakeWordPattern =
      RegExp(r'\b(?:friday|fraidei|sexta(?: feira)?)\b');

  String get confirmation => switch (this) {
        PlaybackCommand.play => 'Reprodução iniciada',
        PlaybackCommand.pause => 'Reprodução pausada',
        PlaybackCommand.next => 'Próxima faixa',
        PlaybackCommand.previous => 'Faixa anterior',
        PlaybackCommand.volumeUp => 'Volume aumentado',
        PlaybackCommand.volumeDown => 'Volume diminuído',
      };

  String get javaScript => switch (this) {
        PlaybackCommand.play => r'''
          (() => {
            const player = document.querySelector('ytmusic-player-bar');
            const video = document.querySelector('video');
            const button = player?.querySelector('#play-pause-button');
            const label = (button?.getAttribute('aria-label') || '').toLowerCase();
            if (button && (label.includes('reproduzir') || label.includes('play'))) {
              button.click();
              return true;
            }
            if (video && video.paused) {
              video.play().catch(() => {});
              return true;
            }
            return !!video;
          })()
        ''',
        PlaybackCommand.pause => r'''
          (() => {
            const video = document.querySelector('video');
            if (video) {
              video.pause();
              return true;
            }
            const button = document.querySelector('ytmusic-player-bar #play-pause-button');
            const label = (button?.getAttribute('aria-label') || '').toLowerCase();
            if (button && (label.includes('pausar') || label.includes('pause'))) {
              button.click();
              return true;
            }
            return false;
          })()
        ''',
        PlaybackCommand.next => _clickPlayerButton('next-button', const [
            'próxima',
            'proxima',
            'seguinte',
            'next',
          ]),
        PlaybackCommand.previous => _clickPlayerButton('previous-button', const [
            'anterior',
            'previous',
          ]),
        PlaybackCommand.volumeUp => _adjustVolume(0.1),
        PlaybackCommand.volumeDown => _adjustVolume(-0.1),
      };

  static String _clickPlayerButton(String id, List<String> labels) {
    final labelList = labels.map((label) => "'$label'").join(', ');
    return '''
      (() => {
        const player = document.querySelector('ytmusic-player-bar');
        const button = player?.querySelector('#$id');
        if (button) {
          button.click();
          return true;
        }
        const labels = [$labelList];
        const candidates = player?.querySelectorAll('button,[role="button"],tp-yt-paper-icon-button') || [];
        const match = Array.from(candidates).find((candidate) => {
          const label = (candidate.getAttribute('aria-label') || candidate.getAttribute('title') || '').toLowerCase();
          return labels.some((value) => label.includes(value));
        });
        if (match) {
          match.click();
          return true;
        }
        return false;
      })()
    ''';
  }

  static String _adjustVolume(double delta) {
    return '''
      (() => {
        const video = document.querySelector('video');
        if (!video) return false;
        video.volume = Math.max(0, Math.min(1, video.volume + $delta));
        video.dispatchEvent(new Event('volumechange'));
        return true;
      })()
    ''';
  }

  static PlaybackCommand? fromPhrase(String phrase) {
    final normalized = _normalize(phrase);
    if (normalized.isEmpty) return null;

    if (_containsAny(normalized, const [
      'aumentar volume',
      'aumenta volume',
      'aumentar o volume',
      'aumenta o volume',
      'subir volume',
      'subir o volume',
      'volume mais',
      'mais alto',
    ])) {
      return PlaybackCommand.volumeUp;
    }
    if (_containsAny(normalized, const [
      'diminuir volume',
      'diminui volume',
      'diminuir o volume',
      'diminui o volume',
      'abaixar volume',
      'abaixa o volume',
      'abaixar o volume',
      'baixar volume',
      'baixar o volume',
      'volume menos',
      'mais baixo',
    ])) {
      return PlaybackCommand.volumeDown;
    }
    if (_containsAny(normalized, const [
      'proxima',
      'proximo',
      'seguinte',
      'next',
    ])) {
      return PlaybackCommand.next;
    }
    if (_containsAny(normalized, const [
      'anterior',
      'voltar musica',
      'previous',
    ])) {
      return PlaybackCommand.previous;
    }
    if (_containsAny(normalized, const [
      'pausar',
      'pausa',
      'parar',
      'pare',
      'stop',
    ])) {
      return PlaybackCommand.pause;
    }
    if (_containsAny(normalized, const [
      'tocar',
      'toque',
      'reproduzir',
      'continuar',
      'retomar',
      'play',
    ])) {
      return PlaybackCommand.play;
    }
    return null;
  }

  static PlaybackCommand? fromWakePhrase(String phrase) {
    final normalized = _normalize(phrase);
    final wakeWord = _wakeWordPattern.firstMatch(normalized);
    if (wakeWord == null) return null;
    return fromPhrase(normalized.substring(wakeWord.end));
  }

  static bool containsWakeWord(String phrase) =>
      _wakeWordPattern.hasMatch(_normalize(phrase));

  static bool _containsAny(String text, List<String> terms) =>
      terms.any(text.contains);

  static String _normalize(String phrase) {
    return phrase
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
