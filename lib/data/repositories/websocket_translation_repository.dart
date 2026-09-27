import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/translation_frame.dart';
import 'translation_repository.dart';

class WebSocketTranslationRepository implements TranslationRepository {
  final Uri serverUri;
  WebSocketChannel? _channel;
  StreamController<TranslationFrame>? _streamController;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isTranslating = false;
  String _currentLanguage = 'en';
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  WebSocketTranslationRepository({
    Uri? serverUri,
  }) : serverUri = serverUri ?? Uri.parse('wss://api.handtech.io/v1/translate');

  @override
  Stream<TranslationFrame> streamTranslations() {
    _streamController ??= StreamController<TranslationFrame>.broadcast();
    return _streamController!.stream;
  }

  @override
  Future<void> startTranslation() async {
    _isTranslating = true;
    _reconnectAttempts = 0;
    _streamController ??= StreamController<TranslationFrame>.broadcast();
    await _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    try {
      _channel = WebSocketChannel.connect(serverUri);
      
      // Send initial configuration frame with selected language
      _channel!.sink.add(jsonEncode({
        'type': 'config',
        'language': _currentLanguage,
      }));

      _startHeartbeat();

      _channel!.stream.listen(
        (dynamic message) {
          _handleIncomingMessage(message);
        },
        onError: (error) {
          _handleStreamError(error);
        },
        onDone: () {
          _handleStreamDone();
        },
      );
    } catch (e) {
      _handleStreamError(e);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_channel != null && _isTranslating) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()}));
        } catch (_) {
          // Heartbeat failed to send
        }
      }
    });
  }

  void _handleIncomingMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message.toString());
      final String type = data['type'] ?? 'translation_frame';

      if (type == 'pong') {
        // Heartbeat response acknowledged
        return;
      }

      if (type == 'translation_frame' || data.containsKey('recognized_text') || data.containsKey('text')) {
        final text = data['recognized_text'] ?? data['text'] ?? '';
        final confidence = (data['confidence_score'] ?? data['confidence'] ?? 1.0).toDouble();
        final isFinal = data['is_final'] ?? data['isFinal'] ?? true;
        final language = data['detected_sign_language'] ?? data['language'] ?? _currentLanguage;
        final timestampStr = data['timestamp'];
        final timestamp = timestampStr != null ? DateTime.tryParse(timestampStr) ?? DateTime.now() : DateTime.now();

        final frame = TranslationFrame(
          timestamp: timestamp,
          recognizedText: text,
          confidenceScore: confidence,
          isFinal: isFinal,
          detectedSignLanguage: language,
        );

        if (_streamController != null && !_streamController!.isClosed) {
          _streamController!.add(frame);
        }
      }
    } catch (_) {
      // Invalid message format ignored
    }
  }

  void _handleStreamError(Object error) {
    if (_streamController != null && !_streamController!.isClosed) {
      _streamController!.addError(error);
    }
    _attemptReconnect();
  }

  void _handleStreamDone() {
    if (_isTranslating) {
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (!_isTranslating) return;

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delaySeconds = 1 << _reconnectAttempts; // 2, 4, 8...
      
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
        if (_isTranslating) {
          _connectWebSocket();
        }
      });
    }
  }

  @override
  Future<void> stopTranslation() async {
    _isTranslating = false;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    
    if (_streamController != null && !_streamController!.isClosed) {
      await _streamController!.close();
      _streamController = null;
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    if (_channel != null && _isTranslating) {
      try {
        _channel!.sink.add(jsonEncode({
          'type': 'config',
          'language': languageCode,
        }));
      } catch (_) {}
    }
  }
}
