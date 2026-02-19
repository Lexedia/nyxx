import 'package:penyxx/src/builders/builder.dart';
import 'package:penyxx/src/builders/sentinels.dart';
import 'package:penyxx/src/models/guild/guild_widget.dart';
import 'package:penyxx/src/models/snowflake.dart';

class WidgetSettingsUpdateBuilder extends UpdateBuilder<WidgetSettings> {
  bool? isEnabled;

  Snowflake? channelId;

  WidgetSettingsUpdateBuilder({this.isEnabled, this.channelId = sentinelSnowflake});

  @override
  Map<String, Object?> build() => {
        if (isEnabled != null) 'enabled': isEnabled,
        if (!identical(channelId, sentinelSnowflake)) 'channel_id': channelId?.toString(),
      };
}
