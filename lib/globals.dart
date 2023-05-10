library globals;

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';

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

const bool enableContact = false;

/// A global variable showing whether to allow self message tile.
///
/// A self message tile aligns to the right side of the screen, and is used to
/// display messages sent by the user.
const bool enableSelfMsgTile = false;

EventBus eventBus = EventBus();
