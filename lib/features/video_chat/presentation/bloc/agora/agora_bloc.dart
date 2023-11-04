import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocechat_client/features/video_chat/domain/usecases/agora_init.dart';
import 'package:vocechat_client/features/video_chat/presentation/bloc/agora/agora_event.dart';
import 'package:vocechat_client/features/video_chat/presentation/bloc/agora/agora_state.dart';

class AgoraBloc extends Bloc<AgoraEvent, AgoraState> {
  final AgoraInitUseCase _agoraJoinUseCase;

  AgoraBloc(this._agoraJoinUseCase) : super(const AgoraConnecting()) {
    on<AgoraJoinChannel>(onConnected);
  }

  void onConnected(AgoraJoinChannel event, Emitter<AgoraState> emit) async {
    // final dataState = await _initJoinAgoraUseCase.call(params: event.params);
  }
}
