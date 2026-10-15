import 'package:nyxx/src/api_options.dart';
import 'package:nyxx/src/models/gateway/event.dart';
import 'package:nyxx/src/models/gateway/opcode.dart';
import 'package:nyxx/src/utils/to_string_helper/to_string_helper.dart';

/// {@template shard_data}
/// Information a shard needs to run itself.
/// {@endtemplate}
class ShardData with ToStringHelper {
  /// The total number of shards in the current session.
  final int totalShards;

  /// The ID of the current shard.
  final int id;

  /// The API options the client is using.
  final GatewayApiOptions apiOptions;

  /// The original connection URI from [GatewayManager.fetchGatewayBot].
  final Uri originalConnectionUri;

  /// The session to resume instead of identifying, if any.
  final ShardSession? session;

  /// {@macro shard_data}
  const ShardData({
    required this.totalShards,
    required this.id,
    required this.apiOptions,
    required this.originalConnectionUri,
    this.session,
  });
}

/// {@template shard_session}
/// The information needed to resume a shard's Gateway session, possibly from another process.
/// {@endtemplate}
///
/// Discord keeps a session open for a short while after its connection is closed, unless it was closed with a 1000
/// or 1001 code.
/// Resuming it replays the events that were dispatched in the meantime.
///
/// {@category gateway}
class ShardSession with ToStringHelper {
  /// The ID of the session.
  final String sessionId;

  /// The sequence number of the last event received on the session.
  final int seq;

  /// The URL to connect to when resuming the session, without any query parameters added by nyxx.
  final Uri resumeUri;

  /// The total number of shards when the session was created. The session can't be resumed with a different count.
  final int totalShards;

  /// {@macro shard_session}
  const ShardSession({
    required this.sessionId,
    required this.seq,
    required this.resumeUri,
    required this.totalShards,
  });

  factory ShardSession.fromJson(Map<String, Object?> json) => ShardSession(
        sessionId: json['session_id'] as String,
        seq: json['seq'] as int,
        resumeUri: Uri.parse(json['resume_url'] as String),
        totalShards: json['total_shards'] as int,
      );

  Map<String, Object?> toJson() => {
        'session_id': sessionId,
        'seq': seq,
        'resume_url': resumeUri.toString(),
        'total_shards': totalShards,
      };
}

/// The base class for all control messages sent from the shard to the client.
///
/// {@category gateway}
abstract class ShardMessage with ToStringHelper {}

/// A shard message sent when an event is received on the Gateway.
///
/// {@category gateway}
class EventReceived extends ShardMessage {
  /// The event that was received.
  final GatewayEvent event;

  /// Create a new [EventReceived].
  EventReceived({required this.event});
}

/// A shard message sent when the shard encounters an error.
///
/// {@category gateway}
class ErrorReceived extends ShardMessage {
  /// The error encountered.
  final Object error;

  /// The stack trace where the error occurred.
  final StackTrace stackTrace;

  /// Create a new [ErrorReceived].
  ErrorReceived({required this.error, required this.stackTrace});
}

/// A shard message sent when the shard is going to disconnect permanently.
///
/// {@category gateway}
class Disconnecting extends ShardMessage {
  /// The reason why the shard is disconnecting.
  final String reason;

  /// The session left open on Discord's side, if the shard was disposed with [Dispose.keepSession] and had one.
  final ShardSession? session;

  /// Create a new [Disconnecting].
  Disconnecting({required this.reason, this.session});
}

/// A shard message sent when the shard adds a payload to the connection.
///
/// {@category gateway}
class Sent extends ShardMessage {
  /// The payload that was sent.
  final Send payload;

  /// Create a new [Sent].
  Sent({required this.payload});
}

/// A shard message sent when the shard is waiting to identify on the Gateway.
///
/// {@category gateway}
class RequestingIdentify extends ShardMessage {}

/// A shard message sent when the shard needs to reconnect to the Gateway.
///
/// {@category gateway}
class Reconnecting extends ShardMessage {
  final String reason;

  Reconnecting({required this.reason});
}

/// The base class for all control messages sent from the client to the shard.
///
/// {@category gateway}
abstract class GatewayMessage with ToStringHelper {}

/// A gateway message sent to instruct the shard to send data on its connection.
///
/// {@category gateway}
class Send extends GatewayMessage {
  /// The opcode of the event to send.
  final Opcode opcode;

  /// The data of the event to send.
  final dynamic data;

  /// Create a new [Send].
  Send({required this.opcode, required this.data});
}

/// A gateway message sent when the [Gateway] instance is ready for the shard to start.
///
/// {@category gateway}
class StartShard extends GatewayMessage {}

/// A gateway message sent as a response to [RequestingIdentify] to allow the shard to identify.
///
/// {@category gateway}
class Identify extends GatewayMessage {}

/// A gateway message sent to instruct the shard to disconnect & stop handling any further messages.
///
/// {@category gateway}
///
/// The shard can no longer be used after this is sent.
class Dispose extends GatewayMessage {
  /// Whether to leave the session open on Discord's side so it can be resumed later, see [ShardSession].
  final bool keepSession;

  Dispose({this.keepSession = false});
}

/// A gateway message sent to instruct the shard to end its current connection and create a new one.
///
/// Cannot be used to restart a disconnected shard.
///
/// {@category gateway}
class Reconnect extends GatewayMessage {
  final bool allowResume;

  Reconnect({this.allowResume = true});
}
