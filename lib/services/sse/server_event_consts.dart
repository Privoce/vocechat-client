const chatEvent = "chat";
const groupChangedEvent = "group_changed";
const heartbeatEvent = "heartbeat";
const joinedGroupEvent = "joined_group";
const kickEvent = "kick";
const kickFromGroupEvent = "kick_from_group";
const messageClearedEvent = "message_cleared";
const pinnedMessageUpdatedEvent = "pinned_message_updated";
const readyEvent = "ready";
const relatedGroupsEvent = "related_groups";
const serverConfigChangedEvent = "server_config_changed";
const userJoinedGroupEvent = "user_joined_group";
const userLeavedGroupEvent = "user_leaved_group";
const usersLogEvent = "users_log";
const userSettingsEvent = "user_settings";
const userSettingsChangedEvent = "user_settings_changed";
const usersSnapshotEvent = "users_snapshot";
const usersStateEvent = "users_state";
const usersStateChangedEvent = "users_state_changed";

const chatMsgNormal = "normal";
const chatMsgReaction = "reaction";
const chatMsgReply = "reply";

typedef ServerEventAware = void Function(dynamic);
typedef ServerEventReadyAware = void Function(bool ready);
