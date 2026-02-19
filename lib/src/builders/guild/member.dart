import 'package:penyxx/src/builders/builder.dart';
import 'package:penyxx/src/builders/sentinels.dart';
import 'package:penyxx/src/models/guild/member.dart';
import 'package:penyxx/src/models/snowflake.dart';
import 'package:penyxx/src/utils/flags.dart';

class MemberBuilder extends CreateBuilder<Member> {
  String accessToken;

  Snowflake userId;

  String? nick;

  List<Snowflake>? roleIds;

  bool? isMute;

  bool? isDeaf;

  MemberBuilder({required this.accessToken, required this.userId, this.nick, this.roleIds, this.isMute, this.isDeaf});

  @override
  Map<String, Object?> build() => {
    'access_token': accessToken,
    if (nick != null) 'nick': nick,
    if (roleIds != null) 'roles': roleIds!.map((e) => e.toString()).toList(),
    if (isMute != null) 'mute': isMute,
    if (isDeaf != null) 'deaf': isDeaf,
  };
}

class MemberUpdateBuilder extends UpdateBuilder<Member> {
  String? nick;

  List<Snowflake>? roleIds;

  bool? isMute;

  bool? isDeaf;

  Snowflake? voiceChannelId;

  DateTime? communicationDisabledUntil;

  Flags<MemberFlags>? flags;

  MemberUpdateBuilder({
    this.nick = sentinelString,
    this.roleIds,
    this.isMute,
    this.isDeaf,
    this.voiceChannelId = sentinelSnowflake,
    this.communicationDisabledUntil = sentinelDateTime,
    this.flags,
  });

  @override
  Map<String, Object?> build() => {
    if (!identical(nick, sentinelString)) 'nick': nick,
    if (roleIds != null) 'roles': roleIds!.map((e) => e.toString()).toList(),
    if (isMute != null) 'mute': isMute,
    if (isDeaf != null) 'deaf': isDeaf,
    if (!identical(voiceChannelId, sentinelSnowflake)) 'channel_id': voiceChannelId?.toString(),
    if (!identical(communicationDisabledUntil, sentinelDateTime)) 'communication_disabled_until': communicationDisabledUntil?.toIso8601String(),
    if (flags != null) 'flags': flags!.value,
  };
}

class CurrentMemberUpdateBuilder extends UpdateBuilder<Member> {
  String? nick;

  CurrentMemberUpdateBuilder({this.nick = sentinelString});

  @override
  Map<String, Object?> build() => {if (!identical(nick, sentinelString)) 'nick': nick};
}

class MemberFilterBuilder extends Builder<void> {
  /// Query to match member ids against.
  ///
  /// Only use [QueryBuilder.range] or [QueryBuilder.orQuery].
  QueryBuilder<Snowflake>? userId;

  /// Query to match display name(s), username(s), and nickname(s) against.
  ///
  /// Only use [QueryBuilder.orQuery].
  QueryBuilder<String>? usernames;

  /// IDs of roles to match members against.
  ///
  /// Only use [QueryBuilder.orQuery] or [QueryBuilder.andQuery].
  QueryBuilder<Snowflake>? roleIds;

  /// When the user joined the guild.
  ///
  /// Only use [QueryBuilder.range].
  QueryBuilder<int>? guildJoinedAt;

  ///  Safety signals to match members against.
  SafetySignalsBuilder? safetySignals;

  /// Whether the member has not yet passed the guild's member verification requirements.
  bool? isPending;

  /// Whether the member left and rejoined the guild.
  bool? didRejoin;

  /// How the user joined the guild.
  ///
  /// Only use [QueryBuilder.orQuery].
  QueryBuilder<int>? joinSourceType;

  /// The invite code or vanity used to join the guild.
  ///
  /// Only use [QueryBuilder.orQuery].
  QueryBuilder<String>? sourceInviteCode;

  MemberFilterBuilder({
    this.didRejoin,
    this.guildJoinedAt,
    this.isPending,
    this.joinSourceType,
    this.roleIds,
    this.safetySignals,
    this.sourceInviteCode,
    this.userId,
    this.usernames,
  });

  @override
  Map<String, Object?> build() => {
    if (userId != null) 'user_id': userId!.build(),
    if (usernames != null) 'usernames': usernames!.build(),
    if (roleIds != null) 'role_ids': roleIds!.build(),
    if (guildJoinedAt != null) 'guild_joined_at': guildJoinedAt!.build(),
    if (isPending != null) 'is_pending': isPending,
    if (didRejoin != null) 'did_rejoin': didRejoin,
    if (joinSourceType != null) 'join_source_type': joinSourceType!.build(),
    if (sourceInviteCode != null) 'source_invite_code': sourceInviteCode!.build(),
  };
}

class QueryBuilder<T /* extends String | Snowflake | int */> extends Builder<void> {
  /// The values to match against using OR logic (1-100 characters, max 10).
  List<T>? orQuery;

  /// The values to match against using AND logic (1-100 characters, max 10).
  List<T>? andQuery;

  /// The range of values to match against.
  RangeQueryBuilder? range;

  QueryBuilder({this.andQuery, this.orQuery, this.range});

  @override
  Map<String, Object?> build() => {
    if (orQuery != null) 'or_query': orQuery!.map((v) => v is Snowflake ? v.value : v).toList(),
    if (andQuery != null) 'and_query': andQuery!.map((v) => v is Snowflake ? v.value : v).toList(),
    if (range != null && (range?.gte != null || range?.lte != null)) 'range': range!.build(),
  };
}

class RangeQueryBuilder extends Builder<void> {
  /// Inclusive lower bound value to match.
  /* Snowflake? | int? */
  dynamic gte;

  /// Inclusive upper bound value to match
  /* Snowflake? | int? */
  dynamic lte;

  RangeQueryBuilder({this.gte, this.lte});

  @override
  Map<String, Object?> build() => {if (gte != null) 'gte': gte is Snowflake ? gte.value : gte, if (lte != null) 'lte': lte is Snowflake ? lte.value : lte};
}

class SafetySignalsBuilder extends Builder<void> {
  /// When the member's unusual DM activity flag will expire.
  ///
  /// Only use [QueryBuilder.range].
  QueryBuilder<int>? unusualDmActivityUntil;

  /// When the member's [timeout](https://support.discord.com/hc/en-us/articles/4413305239191-Time-Out-FAQ) will expire.
  ///
  /// Only use [QueryBuilder.range].
  QueryBuilder<int>? communicationDisabledUntil;

  /// Whether unusual account activity is detected.
  bool? unusualAccountActivity;

  /// Whether the member has been indefinitely quarantined by an [AutoModRule] for their username, display name, or nickname.
  bool? automodQuarantinedUsername;

  SafetySignalsBuilder({this.automodQuarantinedUsername, this.communicationDisabledUntil, this.unusualAccountActivity, this.unusualDmActivityUntil});

  @override
  Map<String, Object?> build() => {
    if (unusualDmActivityUntil != null) 'unusual_dm_activity_until': unusualDmActivityUntil!.build(),
    if (communicationDisabledUntil != null) 'communication_disabled_until': communicationDisabledUntil!.build(),
    if (unusualAccountActivity != null) 'unusual_account_activity': unusualAccountActivity!,
    if (automodQuarantinedUsername != null) 'automod_quarantined_username': automodQuarantinedUsername!,
  };
}

class MemberPaginationFilter extends Builder<void> {
  /// The id of the user to paginate past.
  Snowflake userId;

  /// When the user to paginate past joined the guild.
  int guildJoinedAt;

  MemberPaginationFilter({required this.guildJoinedAt, required this.userId});

  @override
  Map<String, Object?> build() => {'user_id': userId.value, 'guild_joined_at': guildJoinedAt};
}
