import 'dart:convert';

import 'package:nyxx/src/builders/guild/member.dart';
import 'package:nyxx/src/errors.dart';
import 'package:nyxx/src/http/managers/manager.dart';
import 'package:nyxx/src/http/request.dart';
import 'package:nyxx/src/http/route.dart';
import 'package:nyxx/src/models/guild/member.dart';
import 'package:nyxx/src/models/permissions.dart';
import 'package:nyxx/src/models/snowflake.dart';
import 'package:nyxx/src/utils/cache_helpers.dart';
import 'package:nyxx/src/utils/parsing_helpers.dart';
import 'package:nyxx/src/utils/to_string_helper/to_string_helper.dart';

/// A manager for [Member]s.
class MemberManager extends Manager<Member> {
  /// The ID of the [Guild] this manager is for.
  final Snowflake guildId;

  MemberManager(super.config, super.client, {required this.guildId}) : super(identifier: '$guildId.members');

  @override
  PartialMember operator [](Snowflake id) => PartialMember(id: id, manager: this);

  @override
  Member parse(Map<String, Object?> raw, {Snowflake? userId}) {
    final avatarDecorationData = maybeParse(raw['avatar_decoration_data'], client.users.parseAvatarDecorationData);

    return Member(
      id: maybeParse((raw['user'] as Map<String, Object?>?)?['id'], Snowflake.parse) ?? userId ?? Snowflake.zero,
      manager: this,
      user: maybeParse(raw['user'], client.users.parse),
      nick: raw['nick'] as String?,
      avatarHash: raw['avatar'] as String?,
      bannerHash: raw['banner'] as String?,
      roleIds: parseMany(raw['roles'] as List, Snowflake.parse),
      joinedAt: DateTime.parse(raw['joined_at'] as String),
      premiumSince: maybeParse(raw['premium_since'], DateTime.parse),
      isDeaf: raw['deaf'] as bool?,
      isMute: raw['mute'] as bool?,
      flags: MemberFlags(raw['flags'] as int),
      isPending: raw['pending'] as bool? ?? false,
      permissions: maybeParse(raw['permissions'], (String raw) => Permissions(int.parse(raw))),
      communicationDisabledUntil: maybeParse(raw['communication_disabled_until'], DateTime.parse),
      avatarDecorationData: avatarDecorationData,
      avatarDecorationHash: avatarDecorationData?.asset,
    );
  }

  SupplementalGuildMember parseSupplementalGuildMember(Map<String, Object?> raw) {
    return SupplementalGuildMember(
      integrationType: raw['integration_type'] as int?,
      inviterId: maybeParse(raw['inviter_id'], Snowflake.parse),
      joinSourceType: JoinSourceType(raw['join_source_type'] as int),
      member: parse(raw['member'] as Map<String, Object?>),
      sourceInviteCode: raw['source_invite_code'] as String?,
    );
  }

  QueryGuildMembersResponse parseQueryMembersResponse(Map<String, Object?> raw) {
    return QueryGuildMembersResponse(
      guildId: Snowflake.parse(raw['guild_id']!),
      members: parseMany(raw['members'] as List, parseSupplementalGuildMember),
      pageResultCount: raw['page_result_count'] as int,
      totalResultCount: raw['total_result_count'] as int,
    );
  }

  @override
  Future<Member> fetch(Snowflake id) async {
    final route =
        HttpRoute()
          ..guilds(id: guildId.toString())
          ..members(id: id.toString());
    final request = BasicRequest(route);

    final response = await client.httpHandler.executeSafe(request);
    final member = parse(response.jsonBody as Map<String, Object?>, userId: id);

    client.updateCacheWith(member);
    return member;
  }

  /// List the members in the guild.
  Future<List<Member>> list({int? limit, Snowflake? after}) async {
    final route =
        HttpRoute()
          ..guilds(id: guildId.toString())
          ..members();
    final request = BasicRequest(route, queryParameters: {if (limit != null) 'limit': limit.toString(), if (after != null) 'after': after.toString()});

    final response = await client.httpHandler.executeSafe(request);
    final members = parseMany(response.jsonBody as List, parse);

    members.forEach(client.updateCacheWith);
    return members;
  }

  @override
  Future<Member> create(MemberBuilder builder) async {
    final route =
        HttpRoute()
          ..guilds(id: guildId.toString())
          ..members(id: builder.userId.toString());
    final request = BasicRequest(route, method: 'PUT', body: jsonEncode(builder.build()));

    final response = await client.httpHandler.executeSafe(request);
    if (response.statusCode == 204) {
      throw MemberAlreadyExistsException(guildId, builder.userId);
    }

    final member = parse(response.jsonBody as Map<String, Object?>, userId: builder.userId);

    client.updateCacheWith(member);
    return member;
  }

  @override
  Future<Member> update(Snowflake id, MemberUpdateBuilder builder, {String? auditLogReason}) async {
    final route =
        HttpRoute()
          ..guilds(id: guildId.toString())
          ..members(id: id.toString());
    final request = BasicRequest(route, method: 'PATCH', auditLogReason: auditLogReason, body: jsonEncode(builder.build()));

    final response = await client.httpHandler.executeSafe(request);
    final member = parse(response.jsonBody as Map<String, Object?>, userId: id);

    client.updateCacheWith(member);
    return member;
  }

  /// Kick a member.
  @override
  Future<void> delete(Snowflake id, {String? auditLogReason}) async {
    final route =
        HttpRoute()
          ..guilds(id: guildId.toString())
          ..members(id: id.toString());
    final request = BasicRequest(route, method: 'DELETE', auditLogReason: auditLogReason);

    await client.httpHandler.executeSafe(request);
    cache.remove(id);
  }

  /// Search for members whose username begins with [query].
  Future<List<Member>> search(String query, {int? limit}) async {
    final route =
        HttpRoute()
          ..guilds(id: guildId.toString())
          ..members()
          ..search();
    final request = BasicRequest(route, queryParameters: {'query': query, if (limit != null) 'limit': limit.toString()});

    final response = await client.httpHandler.executeSafe(request);
    final members = parseMany(response.jsonBody as List, parse);

    members.forEach(client.updateCacheWith);
    return members;
  }

  /// Returns a wrapped response of [SupplementalGuildMember] objects containing [Member] objects that match a specified query. Requires the `MANAGE_GUILD` permission.
  ///
  /// This endpoint utilizes Elasticsearch to power results. This means that while it is very powerful, it's also tricky to use and reliant on the index, meaning results may not be immediately available for a recently-joined member.
  /// [limit] is the max number of members to return (1-1000, default 25).
  /// [sort] is the sorting algorithm to use, default [MemberSortType.joinedAtDesc].
  ///
  Future<QueryGuildMembersResponse> query({
    int? limit,
    MemberSortType? sort,
    MemberFilterBuilder? orQuery,
    MemberFilterBuilder? andQuery,
    MemberPaginationFilter? before,
    MemberPaginationFilter? after,
  }) async {
    final request = BasicRequest(
      HttpRoute()
        ..guilds(id: guildId.toString())
        ..membersSearch(),
      body: jsonEncode({
        if (limit != null) 'limit': limit,
        if (sort != null) 'sort': sort.value,
        if (orQuery != null) 'or_query': orQuery.build(),
        if (andQuery != null) 'and_query': andQuery.build(),
        if (before != null) 'before': before.build(),
        if (after != null) 'after': after.build(),
      }),
      method: 'POST',
    );

    final response = await client.httpHandler.executeSafe(request);

    if (response.statusCode == 202) {
      throw NyxxException('Try to poll this endpoint after ${response.jsonBody['retry_after']} minutes');
    }

    return parseQueryMembersResponse(response.jsonBody);
  }

  /// Update the current member in the guild.
  Future<Member> updateCurrentMember(CurrentMemberUpdateBuilder builder, {String? auditLogReason}) async {
    final route =
        HttpRoute()
          ..guilds(id: guildId.toString())
          ..members(id: '@me');
    final request = BasicRequest(route, method: 'PATCH', body: jsonEncode(builder.build()), auditLogReason: auditLogReason);

    final response = await client.httpHandler.executeSafe(request);
    final member = parse(response.jsonBody as Map<String, Object?>, userId: client.user.id);

    client.updateCacheWith(member);
    return member;
  }

  /// Add a role to a member in the guild.
  Future<void> addRole(Snowflake id, Snowflake roleId, {String? auditLogReason}) async {
    final route =
        HttpRoute()
          ..guilds(id: guildId.toString())
          ..members(id: id.toString())
          ..roles(id: roleId.toString());
    final request = BasicRequest(route, method: 'PUT', auditLogReason: auditLogReason);

    await client.httpHandler.executeSafe(request);
  }

  /// Remove a role from a member in the guild.
  Future<void> removeRole(Snowflake id, Snowflake roleId, {String? auditLogReason}) async {
    final route =
        HttpRoute()
          ..guilds(id: guildId.toString())
          ..members(id: id.toString())
          ..roles(id: roleId.toString());
    final request = BasicRequest(route, method: 'DELETE', auditLogReason: auditLogReason);

    await client.httpHandler.executeSafe(request);
  }
}

class QueryGuildMembersResponse with ToStringHelper {
  /// The id of the guild queried.
  final Snowflake guildId;

  /// The resulting members.
  final List<SupplementalGuildMember> members;

  /// The number of results returned.
  final int pageResultCount;

  /// The total number of results found.
  final int totalResultCount;

  QueryGuildMembersResponse({required this.guildId, required this.members, required this.pageResultCount, required this.totalResultCount});
}
