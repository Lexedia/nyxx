import 'package:penyxx/src/builders/builder.dart';
import 'package:penyxx/src/models/channel/types/forum.dart';
import 'package:penyxx/src/models/snowflake.dart';
import 'package:penyxx/src/utils/building_helpers.dart';

class ForumTagBuilder extends CreateBuilder<ForumTag> {
  /// The name of the tag. (0-20 characters)
  String name;

  /// Whether this tag can only be added to or removed from threads by a member with the [Permissions.manageThreads] permission.
  bool? isModerated;

  /// The id of a guild's custom emoji.
  Snowflake? emojiId;

  /// The unicode character of the emoji.
  String? emojiName;

  ForumTagBuilder({required this.name, this.isModerated, this.emojiId, this.emojiName});

  @override
  Map<String, Object?> build() => {
        'name': name,
        if (isModerated != null) 'moderated': isModerated,
        ...makeEmojiMap(emojiId: emojiId, emojiName: emojiName),
      };
}
