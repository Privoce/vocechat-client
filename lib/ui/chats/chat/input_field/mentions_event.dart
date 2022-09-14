import 'package:event_bus/event_bus.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';

// Create EventBus
EventBus eventBus = EventBus();

// Event Listening
class MentionsEvent {
  //Receiving Data
  String mentionsMarkupText;
  MentionsEvent(this.mentionsMarkupText);
}

class MentionsTextEvent {
  //Receiving Data
  String text;
  String id;
  MentionsTextEvent(this.text, this.id);
}

class MsgProgressPercentEvent {
  double progressPercent;
  String localMid;
  MsgProgressPercentEvent(this.progressPercent, this.localMid);
}

// Event Model
class SendMessageStatusEvent {
  String status;
  SendMessageStatusEvent(this.status);
}

class SendFireMessageEvent {
  ChatMsgM chatMsgM;
  String localMid;
  dynamic data;
  SendFireMessageEvent(this.chatMsgM, this.localMid, this.data);
}

class ChangeMessageStatusByMidEvent {
  int mid;
  MsgSendStatus status;
  ChangeMessageStatusByMidEvent(this.mid, this.status);
}

class ChangeSendTypeEvent {
  SendType type = SendType.normal;
  ChangeSendTypeEvent(this.type);
}

class CallOnCancelReplyEvent {
  bool cancelReply;
  CallOnCancelReplyEvent(this.cancelReply);
}
