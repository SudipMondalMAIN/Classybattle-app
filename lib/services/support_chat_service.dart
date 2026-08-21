import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../core/token_storage.dart';
import '../models/support_chat_model.dart';
import 'home_service.dart' show UnauthenticatedException;

/// REST calls for the user's support session -- used to render the
/// screen instantly on open (before the socket connects) and as a
/// fallback if the socket can't be reached.
class SupportChatService {
  SupportChatService(this._dio);

  final Dio _dio;

  /// GET /support/session -- the user's open session (auto-created if
  /// none exists) plus its full transcript.
  Future<SupportChatSessionWithMessages> fetchSession() async {
    try {
      final res = await _dio.get('/support/session');
      return SupportChatSessionWithMessages.fromJson(
        res.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /support/session/{id}/messages -- REST fallback for sending
  /// when the socket isn't connected.
  Future<SupportChatSessionWithMessages> sendMessage(
    String sessionId,
    String content,
  ) async {
    try {
      final res = await _dio.post(
        '/support/session/$sessionId/messages',
        data: {'content': content},
      );
      return SupportChatSessionWithMessages.fromJson(
        res.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /support/session/{id}/end -- user ends the chat.
  Future<void> endSession(String sessionId) async {
    try {
      await _dio.post('/support/session/$sessionId/end');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }
}

final supportChatService = SupportChatService(ApiClient.instance.dio);

/// Events surfaced by [SupportChatSocket] to the UI layer.
sealed class SupportChatEvent {
  const SupportChatEvent();
}

class SupportChatInitEvent extends SupportChatEvent {
  const SupportChatInitEvent(this.session, this.messages);
  final SupportChatSession session;
  final List<SupportChatMessage> messages;
}

class SupportChatSessionUpdateEvent extends SupportChatEvent {
  const SupportChatSessionUpdateEvent(this.session);
  final SupportChatSession session;
}

class SupportChatMessageEvent extends SupportChatEvent {
  const SupportChatMessageEvent(this.message);
  final SupportChatMessage message;
}

class SupportChatConnectionEvent extends SupportChatEvent {
  const SupportChatConnectionEvent(this.connected);
  final bool connected;
}

/// Wraps the /ws/support/user WebSocket: connects with the current
/// access token, exposes a stream of typed events (init / live message
/// / session update / connection state), and lets the UI push messages
/// and end the chat over the open socket. The backend broadcasts every
/// new message (from the user, the agent, or a system notice like
/// "agent joined") back down this same socket in real time, so the UI
/// never needs to poll.
class SupportChatSocket {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  final _controller = StreamController<SupportChatEvent>.broadcast();

  Stream<SupportChatEvent> get events => _controller.stream;

  Future<void> connect() async {
    final token = await TokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw UnauthenticatedException();
    }
    final uri = Uri.parse('${ApiConfig.wsBaseUrl}/ws/support/user?token=$token');

    try {
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      _channel = channel;
      _controller.add(const SupportChatConnectionEvent(true));

      _sub = channel.stream.listen(
        _handleRaw,
        onDone: () => _controller.add(const SupportChatConnectionEvent(false)),
        onError: (_) => _controller.add(const SupportChatConnectionEvent(false)),
        cancelOnError: false,
      );
    } catch (_) {
      _controller.add(const SupportChatConnectionEvent(false));
      rethrow;
    }
  }

  void _handleRaw(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;
      switch (type) {
        case 'init':
          final session =
              SupportChatSession.fromJson(data['session'] as Map<String, dynamic>);
          final messages = (data['messages'] as List? ?? [])
              .map((e) => SupportChatMessage.fromJson(e as Map<String, dynamic>))
              .toList();
          _controller.add(SupportChatInitEvent(session, messages));
          break;
        case 'session_update':
          final session =
              SupportChatSession.fromJson(data['session'] as Map<String, dynamic>);
          _controller.add(SupportChatSessionUpdateEvent(session));
          break;
        case 'message':
          final message =
              SupportChatMessage.fromJson(data['message'] as Map<String, dynamic>);
          _controller.add(SupportChatMessageEvent(message));
          break;
      }
    } catch (_) {
      // Ignore malformed frames rather than crashing the socket loop.
    }
  }

  void sendMessage(String content) {
    _channel?.sink.add(jsonEncode({'type': 'message', 'content': content}));
  }

  void endChat() {
    _channel?.sink.add(jsonEncode({'type': 'end'}));
  }

  bool get isConnected => _channel != null;

  Future<void> dispose() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    await _controller.close();
  }
}
