enum CallType { audio, video }
enum CallState { ringing, connecting, active, ended, missed, declined }
enum CallDirection { incoming, outgoing }

class CallModel {
  final String id;
  final String chatId;
  final String callerId;
  final String calleeId;
  final CallType type;
  final CallState state;
  final CallDirection direction;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration; // in seconds
  final bool isEncrypted;
  final String? encryptionKey;

  CallModel({
    required this.id,
    required this.chatId,
    required this.callerId,
    required this.calleeId,
    required this.type,
    required this.state,
    required this.direction,
    required this.startTime,
    this.endTime,
    this.duration,
    this.isEncrypted = true,
    this.encryptionKey,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'chatId': chatId,
        'callerId': callerId,
        'calleeId': calleeId,
        'type': type.name,
        'state': state.name,
        'direction': direction.name,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'duration': duration,
        'isEncrypted': isEncrypted,
        'encryptionKey': encryptionKey,
      };

  factory CallModel.fromMap(Map<String, dynamic> map) => CallModel(
        id: map['id'] ?? '',
        chatId: map['chatId'] ?? '',
        callerId: map['callerId'] ?? '',
        calleeId: map['calleeId'] ?? '',
        type: CallType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => CallType.audio,
        ),
        state: CallState.values.firstWhere(
          (e) => e.name == map['state'],
          orElse: () => CallState.ringing,
        ),
        direction: CallDirection.values.firstWhere(
          (e) => e.name == map['direction'],
          orElse: () => CallDirection.outgoing,
        ),
        startTime: map['startTime'] != null
            ? DateTime.parse(map['startTime'])
            : DateTime.now(),
        endTime:
            map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
        duration: map['duration'],
        isEncrypted: map['isEncrypted'] ?? true,
        encryptionKey: map['encryptionKey'],
      );
}
