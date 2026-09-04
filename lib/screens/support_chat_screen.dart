import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

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
  bool _uploadingMedia = false;
  double _uploadProgress = 0;
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

  Future<void> _showAttachSheet() async {
    if (_uploadingMedia || _session?.status == SupportChatStatus.closed) return;
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttachSheet(),
    );
    if (choice == null) return;

    XFile? picked;
    if (choice == 'photo') {
      picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    } else if (choice == 'camera') {
      picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    } else if (choice == 'video') {
      picked = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
    }
    if (picked == null) return;
    await _uploadMedia(File(picked.path));
  }

  Future<void> _uploadMedia(File file) async {
    final session = _session;
    if (session == null) return;
    setState(() {
      _uploadingMedia = true;
      _uploadProgress = 0;
    });
    try {
      await supportChatService.sendMedia(
        session.id,
        file,
        onProgress: (sent, total) {
          if (total <= 0 || !mounted) return;
          setState(() => _uploadProgress = sent / total);
        },
      );
      // No manual insert into _messages here -- the backend broadcasts
      // the new message over the socket (same path as text messages),
      // so it arrives via SupportChatMessageEvent and is deduped there.
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
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
      itemBuilder: (context, i) => _PopIn(
        key: ValueKey(_messages[i].id),
        child: _MessageBubble(message: _messages[i]),
      ),
    );
  }

  Widget _buildInputBar() {
    final closed = _session?.status == SupportChatStatus.closed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_uploadingMedia)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  minHeight: 3,
                  backgroundColor: AppColors.glassBorder,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.purple),
                ),
              ),
            ),
          GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: closed || _uploadingMedia ? null : _showAttachSheet,
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.textSecondary),
                  tooltip: 'Attach photo or video',
                ),
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
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                _SendButton(
                  enabled: !closed && !_sending,
                  loading: _sending,
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
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
        padding: message.isMedia
            ? const EdgeInsets.all(6)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe && !message.isMedia ? AppColors.purpleButton : null,
          color: isMe
              ? (message.isMedia ? AppColors.glassFillStrong : null)
              : AppColors.glassFillStrong,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: (!isMe || message.isMedia)
              ? Border.all(color: AppColors.glassBorder, width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.messageType == SupportChatMessageType.image)
              _ChatImage(url: message.mediaUrl)
            else if (message.messageType == SupportChatMessageType.video)
              _ChatVideo(url: message.mediaUrl),
            if (message.content.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: message.isMedia ? 8 : 0,
                  left: message.isMedia ? 6 : 0,
                  right: message.isMedia ? 6 : 0,
                ),
                child: Text(
                  message.content,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14, height: 1.3),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: message.isMedia ? 6 : 0,
                right: message.isMedia ? 6 : 0,
                bottom: message.isMedia ? 4 : 0,
              ),
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  color: isMe && !message.isMedia
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.textMuted,
                  fontSize: 10,
                ),
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

/// Tapped-open full-screen image preview.
class _ChatImage extends StatelessWidget {
  const _ChatImage({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _FullScreenImage(url: url!)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url!,
          width: 220,
          fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox(
            width: 220,
            height: 160,
            child: Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.purple),
            ),
          ),
          errorWidget: (_, __, ___) => const SizedBox(
            width: 220,
            height: 160,
            child: Icon(Icons.broken_image_outlined,
                color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Inline-playable video bubble: muted looping preview thumbnail that
/// opens a full-screen player with sound + controls on tap.
class _ChatVideo extends StatefulWidget {
  const _ChatVideo({required this.url});
  final String? url;

  @override
  State<_ChatVideo> createState() => _ChatVideoState();
}

class _ChatVideoState extends State<_ChatVideo> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final url = widget.url;
    if (url != null) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        controller
          ..setLooping(true)
          ..setVolume(0)
          ..play();
        setState(() {});
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    if (url == null) return const SizedBox.shrink();
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _FullScreenVideo(url: url)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 220,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (ready)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                )
              else
                const ColoredBox(
                  color: AppColors.glassFillStrong,
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.purple),
                  ),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(color: Colors.black26),
              ),
              const Center(
                child: Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 44),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenVideo extends StatefulWidget {
  const _FullScreenVideo({required this.url});
  final String url;

  @override
  State<_FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<_FullScreenVideo> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller
          ..setVolume(1)
          ..play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _ready
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  }),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      if (!_controller.value.isPlaying)
                        const Icon(Icons.play_circle_fill_rounded,
                            color: Colors.white70, size: 64),
                    ],
                  ),
                ),
              )
            : const CircularProgressIndicator(color: AppColors.purple),
      ),
    );
  }
}

/// One-shot pop/scale-in entrance for a newly built bubble -- gives new
/// messages a snappy WhatsApp-like "arrival" feel instead of just
/// appearing instantly.
class _PopIn extends StatefulWidget {
  const _PopIn({super.key, required this.child});
  final Widget child;

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();
  late final Animation<double> _scale =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.bottomCenter,
        child: widget.child,
      ),
    );
  }
}

/// Send button with a WhatsApp-style tap "pop" -- quick shrink-and-spring
/// back on press, so sending feels immediate before the message even
/// lands in the list.
class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    lowerBound: 0.85,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!widget.enabled) return;
    await _ctrl.reverse();
    await _ctrl.forward();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _ctrl,
      child: IconButton(
        onPressed: widget.enabled ? _handleTap : null,
        icon: widget.loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.purple),
              )
            : const Icon(Icons.send_rounded, color: AppColors.purple),
      ),
    );
  }
}

/// Bottom sheet shown by the attach (+) button -- pick photo / camera /
/// video.
class _AttachSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF14101F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _AttachOption(
              icon: Icons.photo_outlined,
              label: 'Photo from gallery',
              onTap: () => Navigator.of(context).pop('photo'),
            ),
            _AttachOption(
              icon: Icons.videocam_outlined,
              label: 'Video from gallery',
              onTap: () => Navigator.of(context).pop('video'),
            ),
            _AttachOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a photo',
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.purple),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
    );
  }
}
