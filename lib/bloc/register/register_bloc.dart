import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';

part 'register_event.dart';

part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final ChatServerM initialChatServer;

  late ChatServerM _chatServerM;

  bool _rememberMe = false;

  RegisterBloc({
    required this.initialChatServer,
  }) : super(RegisterInitial()) {
    on<RegisterRememberMeSwitched>(_onRegisterRememberMeSwitched);
    on<RegisterTapped>(_onRegisterTapped);

    _chatServerM = initialChatServer.copywith();
  }

  void _onRegisterRememberMeSwitched(
    RegisterRememberMeSwitched event,
    Emitter<RegisterState> emit,
  ) {
    _rememberMe = event.rememberMe;
  }

  void _onRegisterTapped(
    RegisterTapped event,
    Emitter<RegisterState> emit,
  ) {
    emit(RegisterInProgress());

    // TODO: Implement the registration logic,
    // emit RegisterSuccess() if the registration is successful,
    // emit RegisterFailure() if the registration fails.
  }
}
