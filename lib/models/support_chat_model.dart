/// Mirrors the backend's `SupportChatSenderType` enum
/// (app/models/support_chat.py).
enum SupportChatSenderType {
  user,
  agent,
  system;

  static SupportChatSenderType fromRaw(String? raw) {
    switch (raw) {
      case 'agent':
        return SupportChatSenderType.agent;
      case 'system':
        return SupportChatSenderType.system;
      case 'user':
      default:
        return SupportChatSenderType.user;
    }
  }
}

/// Mirrors the backend's `SupportChatStatus` enum.
enum SupportChatStatus {
  waiting,
  active,
  closed;

  static SupportChatStatus fromRaw(String? raw) {
    switch (raw) {
      case 'active':
        return SupportChatStatus.active;
      case 'closed':
        return SupportChatStatus.closed;
      case 'waiting':
      default:
        return SupportChatStatus.waiting;
    }
  }
}

class SupportChatMessage {
  const SupportChatMessage({
    required this.id,
    required this.senderType,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final SupportChatSenderType senderType;
  final String content;
  final DateTime createdAt;

  factory SupportChatMessage.fromJson(Map<String, dynamic> json) {
    return SupportChatMessage(
      id: json['id'].toString(),
      senderType: SupportChatSenderType.fromRaw(json['sender_type'] as String?),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

class SupportChatSession {
  const SupportChatSession({
    required this.id,
    required this.status,
    this.agentId,
  });

  final String id;
  final SupportChatStatus status;
  final String? agentId;

  factory SupportChatSession.fromJson(Map<String, dynamic> json) {
    return SupportChatSession(
      id: json['id'].toString(),
      status: SupportChatStatus.fromRaw(json['status'] as String?),
      agentId: json['agent_id']?.toString(),
    );
  }
}

class SupportChatSessionWithMessages {
  const SupportChatSessionWithMessages({
    required this.session,
    required this.messages,
  });

  final SupportChatSession session;
  final List<SupportChatMessage> messages;

  factory SupportChatSessionWithMessages.fromJson(Map<String, dynamic> json) {
    return SupportChatSessionWithMessages(
      session: SupportChatSession.fromJson(json),
      messages: (json['messages'] as List? ?? [])
          .map((e) => SupportChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
