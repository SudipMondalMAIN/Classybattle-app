import 'package:flutter/material.dart';
import '../models/support_chat_model.dart';
import '../services/home_service.dart' show UnauthenticatedException;
import '../services/support_chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _socket = SupportChatSocket();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<SupportChatMessage> _messages = [];
  SupportChatSession? _session;
  bool _loading = true;
  bool _connected = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _socket.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      // Render instantly from REST, then upgrade to the live socket.
      final data = await supportChatService.fetchSession();
      if (!mounted) return;
      setState(() {
        _session = data.session;
        _messages
          ..clear()
          ..addAll(data.messages);
        _loading = false;
      });
      _scrollToBottom();
      _connect();
    } on UnauthenticatedException {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Please log in to chat with support.';
      });
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Could not load support chat. Pull to retry.';
      });
    }
  }

  Future<void> _connect() async {
    _socket.events.listen((event) {
      if (!mounted) return;
      switch (event) {
        case SupportChatConnectionEvent(:final connected):
          setState(() => _connected = connected);
          break;
        case SupportChatInitEvent(:final session, :final messages):
          setState(() {
            _session = session;
            _messages
              ..clear()
              ..addAll(messages);
          });
          _scrollToBottom();
          break;
        case SupportChatSessionUpdateEvent(:final session):
          setState(() => _session = session);
          break;
        case SupportChatMessageEvent(:final message):
          setState(() {
            if (!_messages.any((m) => m.id == message.id)) {
              _messages.add(message);
            }
          });
          _scrollToBottom();
          break;
      }
    });
    try {
      await _socket.connect();
    } on UnauthenticatedException {
      if (mounted) setState(() => _error = 'Please log in to chat with support.');
    } catch (_) {
      // Socket failed -- user can still send via REST fallback below.
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final content = _inputCtrl.text.trim();
    if (content.isEmpty || _sending) return;
    _inputCtrl.clear();

    if (_socket.isConnected) {
      _socket.sendMessage(content);
      return;
    }

    // REST fallback when the socket isn't up.
    final session = _session;
    if (session == null) return;
    setState(() => _sending = true);
    try {
      final data = await supportChatService.sendMessage(session.id, content);
      if (!mounted) return;
      setState(() {
        _session = data.session;
        _messages
          ..clear()
          ..addAll(data.messages);
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message failed to send. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmEndChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF14101F),
        title: const Text('End chat?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'You can always start a new chat later.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End Chat',
                style: TextStyle(color: AppColors.live)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final session = _session;
    if (_socket.isConnected) {
      _socket.endChat();
    } else if (session != null) {
      try {
        await supportChatService.endSession(session.id);
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientTop,
              AppColors.backgroundGradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
              if (_error == null) _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final status = _session?.status;
    String statusText;
    Color statusColor;
    if (!_connected && !_loading) {
      statusText = 'Reconnecting…';
      statusColor = AppColors.textMuted;
    } else {
      switch (status) {
        case SupportChatStatus.active:
          statusText = 'Agent connected';
          statusColor = AppColors.success;
          break;
        case SupportChatStatus.closed:
          statusText = 'Chat ended';
          statusColor = AppColors.textMuted;
          break;
        case SupportChatStatus.waiting:
        default:
          statusText = 'Waiting for an agent…';
          statusColor = AppColors.gold;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppColors.textPrimary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Live Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_session != null && status != SupportChatStatus.closed)
            IconButton(
              onPressed: _confirmEndChat,
              icon: const Icon(Icons.close_rounded,
                  size: 20, color: AppColors.textSecondary),
              tooltip: 'End chat',
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.purple),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Send a message to start chatting with our support team.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _MessageBubble(message: _messages[i]),
    );
  }

  Widget _buildInputBar() {
    final closed = _session?.status == SupportChatStatus.closed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                enabled: !closed,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: closed
                      ? 'This chat has ended'
                      : 'Type a message…',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            IconButton(
              onPressed: closed || _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.purple),
                    )
                  : const Icon(Icons.send_rounded, color: AppColors.purple),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final SupportChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.senderType == SupportChatSenderType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    final isMe = message.senderType == SupportChatSenderType.user;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.purpleButton : null,
          color: isMe ? null : AppColors.glassFillStrong,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe
              ? null
              : Border.all(color: AppColors.glassBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}
