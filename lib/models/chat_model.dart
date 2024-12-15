import 'package:hive/hive.dart';

part 'chat_model.g.dart';

enum ChatType {
  individual,
  group
}

@HiveType(typeId: 2)
class ChatModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final ChatType type;

  @HiveField(3)
  final List<String> participantIds;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String? lastMessageContent;

  @HiveField(6)
  final DateTime? lastMessageTime;

  ChatModel({
    required this.id,
    required this.name,
    required this.type,
    required this.participantIds,
    required this.createdAt,
    this.lastMessageContent,
    this.lastMessageTime,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ChatType.values.firstWhere(
        (e) => e.toString() == 'ChatType.${json['type']}',
        orElse: () => ChatType.individual,
      ),
      participantIds: List<String>.from(json['participant_ids'] as List),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastMessageContent: json['last_message_content'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'participant_ids': participantIds,
      'created_at': createdAt.toIso8601String(),
      'last_message_content': lastMessageContent,
      'last_message_time': lastMessageTime?.toIso8601String(),
    };
  }
}
