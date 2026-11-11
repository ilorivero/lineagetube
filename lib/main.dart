import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'playback_command.dart';

void main() {
  runApp(const YouTubeMusicVoiceApp());
}

class YouTubeMusicVoiceApp extends StatelessWidget {
  const YouTubeMusicVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Music Voice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF0033),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF090909),
        useMaterial3: true,
      ),
      home: const MusicHomePage(),
    );
  }
}

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage>
    with WidgetsBindingObserver {
  static final Uri _musicUri = Uri.parse('https://music.youtube.com/?hl=pt-BR');

  final SpeechToText _speech = SpeechToText();
  late final WebViewController _webViewController;
  Timer? _recognitionRestartTimer;

  bool _isListening = false;
  bool _wakeWordEnabled = false;
  bool _isInitializingSpeech = false;
  bool _userPausedWakeWord = false;
  bool _awaitingWakeCommand = false;
  bool _commandListenActive = false;
  bool _isStartingRecognition = false;
  bool _isLoading = true;
  bool _speechInitialized = false;
  int _loadProgress = 0;
  String _status = 'Carregando YouTube Music';
  String _lastCommand = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _loadProgress = progress);
            }
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _status = 'Carregando YouTube Music';
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _status = 'Pronto para reproduzir';
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _status = 'Erro ao abrir YouTube Music: ${error.description}';
              });
            }
          },
        ),
      )
      ..loadRequest(_musicUri);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startWakeWordDetection());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recognitionRestartTimer?.cancel();
    unawaited(_speech.stop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _wakeWordEnabled) {
      unawaited(_stopWakeWordDetection(
        status: 'Ativação Friday pausada enquanto o app está em segundo plano',
      ));
    } else if (state == AppLifecycleState.resumed &&
        !_wakeWordEnabled &&
        !_userPausedWakeWord) {
      unawaited(_startWakeWordDetection());
    }
  }

  Future<void> _toggleListening() async {
    if (_wakeWordEnabled) {
      _userPausedWakeWord = true;
      await _stopWakeWordDetection(status: 'Ativação Friday pausada');
      return;
    }

    _userPausedWakeWord = false;
    await _startWakeWordDetection();
  }

  Future<void> _startWakeWordDetection() async {
    if (!mounted || _wakeWordEnabled || _isInitializingSpeech) return;

    _isInitializingSpeech = true;
    setState(() => _status = 'Solicitando acesso ao microfone e preparando Friday');
    try {
      if (!_speechInitialized) {
        final available = await _speech.initialize(
          onStatus: _onSpeechStatus,
          onError: _onSpeechError,
        );
        _speechInitialized = available;
      }

      if (!mounted) return;
      if (!_speechInitialized) {
        setState(() {
          _status =
              'Reconhecimento indisponível. Permita o microfone e o reconhecimento de voz nas configurações do sistema e tente novamente.';
        });
        return;
      }

      final localeId = await _portugueseLocaleId();
      if (!mounted) return;
      setState(() {
        _wakeWordEnabled = true;
        _awaitingWakeCommand = false;
        _commandListenActive = false;
        _status = 'Diga “Friday” (fraidei) ou “sexta-feira” e um comando';
      });
      await _startRecognition(localeId: localeId);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _wakeWordEnabled = false;
          _status = 'Erro de voz: ${error.message ?? error.code}';
        });
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _wakeWordEnabled = false;
          _status = 'Erro ao iniciar voz: $error';
        });
      }
    } finally {
      _isInitializingSpeech = false;
    }
  }

  Future<void> _stopWakeWordDetection({required String status}) async {
    _recognitionRestartTimer?.cancel();
    if (mounted) {
      setState(() {
        _wakeWordEnabled = false;
        _awaitingWakeCommand = false;
        _isListening = false;
        _status = status;
      });
    }
    await _speech.stop();
  }

  Future<void> _startRecognition({String? localeId}) async {
    if (!mounted ||
        !_wakeWordEnabled ||
        _isStartingRecognition ||
        _speech.isListening) {
      return;
    }

    _recognitionRestartTimer?.cancel();
    _isStartingRecognition = true;
    try {
      final awaitingCommand = _awaitingWakeCommand;
      await _speech.listen(
        onResult: _onSpeechResult,
        listenOptions: SpeechListenOptions(
          listenFor: Duration(seconds: awaitingCommand ? 12 : 30),
          pauseFor: Duration(seconds: awaitingCommand ? 7 : 4),
          partialResults: true,
          cancelOnError: false,
          localeId: localeId ?? await _portugueseLocaleId(),
        ),
      );
      _commandListenActive = awaitingCommand;
      if (mounted && _wakeWordEnabled && _speech.isListening) {
        setState(() {
          _isListening = true;
          _status = _awaitingWakeCommand
              ? 'Palavra de ativação detectada. Diga um comando agora'
              : 'Ativação ligada — diga “Friday” ou “sexta-feira”';
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _status = 'Erro no reconhecimento: ${error.message ?? error.code}';
        });
      }
      _scheduleRecognitionRestart();
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _status = 'Erro no reconhecimento: $error';
        });
      }
      _scheduleRecognitionRestart();
    } finally {
      _isStartingRecognition = false;
    }
  }

  void _scheduleRecognitionRestart() {
    if (!mounted || !_wakeWordEnabled) return;
    _recognitionRestartTimer?.cancel();
    _recognitionRestartTimer = Timer(
      const Duration(milliseconds: 900),
      () => unawaited(_startRecognition()),
    );
  }

  Future<String?> _portugueseLocaleId() async {
    final locales = await _speech.locales();
    for (final locale in locales) {
      final id = locale.localeId.toLowerCase().replaceAll('-', '_');
      if (id == 'pt_br') {
        return locale.localeId;
      }
    }
    for (final locale in locales) {
      if (locale.localeId.toLowerCase().startsWith('pt')) {
        return locale.localeId;
      }
    }
    return null;
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
      setState(() {
        _isListening = true;
        _status = _awaitingWakeCommand
            ? 'Palavra de ativação detectada. Diga um comando agora'
            : 'Ativação ligada — diga “Friday” ou “sexta-feira”';
      });
    } else if (status == 'notListening' || status == 'done') {
      setState(() {
        _isListening = false;
        if (_wakeWordEnabled &&
            _awaitingWakeCommand &&
            _commandListenActive) {
          _awaitingWakeCommand = false;
          _commandListenActive = false;
          _status = 'Comando não detectado. Diga “Friday” ou “sexta-feira” novamente';
        }
      });
      _scheduleRecognitionRestart();
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _status = 'Erro de reconhecimento: ${error.errorMsg}';
      if (error.permanent) {
        _wakeWordEnabled = false;
        _awaitingWakeCommand = false;
        _commandListenActive = false;
      }
    });
    if (!error.permanent) _scheduleRecognitionRestart();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    final phrase = result.recognizedWords.trim();
    if (phrase.isEmpty || !result.finalResult) return;
    setState(() => _lastCommand = phrase);

    if (_awaitingWakeCommand) {
      final command = PlaybackCommand.fromPhrase(phrase);
      if (command == null) {
        setState(() {
          _awaitingWakeCommand = false;
          _commandListenActive = false;
          _status = 'Comando não reconhecido. Diga “Friday” ou “sexta-feira” para tentar de novo';
        });
        return;
      }
      _awaitingWakeCommand = false;
      _commandListenActive = false;
      unawaited(_stopRecognitionAndRun(command));
      return;
    }

    final wakeCommand = PlaybackCommand.fromWakePhrase(phrase);
    if (wakeCommand != null) {
      unawaited(_stopRecognitionAndRun(wakeCommand));
    } else if (PlaybackCommand.containsWakeWord(phrase)) {
      setState(() {
        _awaitingWakeCommand = true;
        _commandListenActive = false;
        _status = 'Palavra de ativação detectada. Diga um comando agora';
      });
      unawaited(_speech.stop());
      _scheduleRecognitionRestart();
    }
  }

  Future<void> _stopRecognitionAndRun(PlaybackCommand command) async {
    await _speech.stop();
    await _runCommand(command);
    _scheduleRecognitionRestart();
  }

  Future<void> _runCommand(PlaybackCommand command) async {
    final script = command.javaScript;
    try {
      final result = await _webViewController.runJavaScriptReturningResult(script);
      if (!mounted) return;
      final succeeded = result == true || result == 'true' || result == '"true"';
      setState(() {
        _status = succeeded
            ? command.confirmation
            : 'Não encontrei esse controle no player. Verifique se uma música está aberta.';
      });
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _status = 'Falha ao controlar o player: ${error.message ?? error.code}');
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _status = 'Falha ao controlar o player: $error');
      }
    }
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _status = 'Recarregando YouTube Music';
    });
    await _webViewController.loadRequest(_musicUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Music'),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _loadProgress / 100),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _webViewController)),
          _buildCommandPanel(),
        ],
      ),
    );
  }

  Widget _buildCommandPanel() {
    return Material(
      color: const Color(0xFF171717),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    _isListening ? Icons.graphic_eq : Icons.info_outline,
                    color: _isListening ? const Color(0xFFFF3355) : Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (_lastCommand.isNotEmpty)
                          Text(
                            'Último comando: $_lastCommand',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Faixa anterior',
                    onPressed: () => _runCommand(PlaybackCommand.previous),
                    icon: const Icon(Icons.skip_previous),
                  ),
                  IconButton(
                    tooltip: 'Tocar',
                    onPressed: () => _runCommand(PlaybackCommand.play),
                    icon: const Icon(Icons.play_arrow),
                  ),
                  IconButton(
                    tooltip: 'Pausar',
                    onPressed: () => _runCommand(PlaybackCommand.pause),
                    icon: const Icon(Icons.pause),
                  ),
                  IconButton(
                    tooltip: 'Próxima faixa',
                    onPressed: () => _runCommand(PlaybackCommand.next),
                    icon: const Icon(Icons.skip_next),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _toggleListening,
                    icon: Icon(
                      _wakeWordEnabled ? Icons.mic_off : Icons.mic,
                    ),
                    label: Text(
                      _wakeWordEnabled ? 'Pausar Friday' : 'Ativar Friday',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _wakeWordEnabled
                          ? const Color(0xFF9B1C32)
                          : const Color(0xFFB00020),
                    ),
                  ),
                ],
              ),
              const Text(
                'Diga “Friday” (fraidei) ou “sexta-feira”, seguido de: tocar, pausar, próxima, anterior, volume',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
