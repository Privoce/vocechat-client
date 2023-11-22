import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocechat_client/feature/avchat_call_in/presentation/avchat_callin_events.dart';
import 'package:vocechat_client/feature/avchat_call_in/presentation/avchat_callin_states.dart';

class AvchatCallinBloc extends Bloc<AvchatCallinEvent, AvchatCallInState> {
  AvchatCallinBloc() : super(AvchatCallInInitialState()) {
    on<AvchatCallinInfoReceived>(_onCallinInfoReceived);
  }

  Future<void> _onCallinInfoReceived(
      AvchatCallinInfoReceived event, Emitter<AvchatCallInState> emit) async {
    // emit(AvchatCallInOngoing(event.channelData.channel));
  }
}
