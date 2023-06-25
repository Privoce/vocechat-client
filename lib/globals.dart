library globals;

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/user_settings.dart';

// To use globals, import package as follow:
// import 'package:vocechat_client/globals.dart' as globals;

/// A global variable showing the total number of unread messages.
final ValueNotifier<int> unreadCountSum = ValueNotifier(0);

/// A global variable showing whether to allow Public Channel handling.
///
/// When enabled, both private and public channels will be fetched, saved and
/// displayed. App will only handle private channels otherwise.
///
/// When switched from true to false, database needs to be refreshed. All
/// private channels need be deleted due to safety concerns.
bool enablePublicChannels = true;

final ValueNotifier<UserSettings> userSettings = ValueNotifier(UserSettings());

EventBus eventBus = EventBus();
