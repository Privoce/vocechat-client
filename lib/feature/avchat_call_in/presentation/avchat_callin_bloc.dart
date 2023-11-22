import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/feature/avchat_call_in/model/agora_channel_data.dart';
import 'package:vocechat_client/feature/avchat_call_in/presentation/avchat_callin_events.dart';
import 'package:vocechat_client/feature/avchat_call_in/presentation/avchat_callin_states.dart';
import 'package:vocechat_client/feature/avchat_calling/logic/avchat_api.dart';

class AvchatCallinBloc extends Bloc<AvchatCallinEvent, AvchatCallInState> {
  Timer? _timer;

  bool _agoraEnabled = false;
  bool get agoraEnabled => _agoraEnabled;

  AvchatCallinBloc() : super(AvchatCallInInitialState()) {
    on<AvchatCallinInit>(_onInit);
    on<AvchatCallinEnableRequest>((event, emit) {
      emit(AvchatCallEnabled(enabled: agoraEnabled));
    });
    on<AvchatCallinInfoReceived>(_onCallinInfoReceived);
    on<AgoraCallinReceivingFailEvent>((event, emit) {
      emit(AgoraCallinReceivingFailed(error: event.error));
    });

    add(AvchatCallinInit());
  }

  Future<void> _onInit(
      AvchatCallinInit event, Emitter<AvchatCallInState> emit) async {
    try {
      final enabled = await AvchatApi().isAgoraEnabled();
      _agoraEnabled = enabled;
      emit(AvchatCallEnabled(enabled: enabled));

      if (enabled) {
        App.logger.info("Agora enabled, start polling timer");
        _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
          final channelInfo = await AvchatApi().getChannels();
          if (channelInfo != null && channelInfo.success) {
            App.logger.info("Agora channel info: $channelInfo");
            final channels = channelInfo.data["channels"] as List<dynamic>?;
            final totalSize = channelInfo.data["total_size"] as int?;
            if (channels != null && totalSize != null) {
              final channelData =
                  AgoraChannelData(channels: channels, totalSize: totalSize);
              add(AvchatCallinInfoReceived(channelData: channelData));
            } else {
              final error = "Invalid channel info: $channelInfo";
              App.logger.severe(error);
              add(AgoraCallinReceivingFailEvent(error: error));
            }
          }
        });
      }
    } catch (e) {
      App.logger.severe(e);
      emit(AvchatCallEnabled(enabled: false));
    }
  }

  Future<void> _onCallinInfoReceived(
      AvchatCallinInfoReceived event, Emitter<AvchatCallInState> emit) async {
    final channelData = event.channelData;
    List<int> uids = [];

    for (final channel in channelData.channels) {
      try {
        final detail = await AvchatApi().getChannelUsers(channel.channelname);
        if (detail != null && detail.users.length == 1) {
          uids.add(detail.users.first);
        }
      } catch (e) {
        App.logger.severe(e);
        continue;
      }
    }

    emit(AvchatOngoingCalls(uids: uids, gids: const []));
  }

  void clear() {
    _timer?.cancel();
  }
}
