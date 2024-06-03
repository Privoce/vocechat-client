import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/extensions.dart';
import 'package:vocechat_client/util/error/error_code.dart';
import 'package:vocechat_client/util/error/voce_error.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final ChatServerM initialChatServer;

  late ChatServerM _chatServerM;

  late UserApi _userApi;

  bool _rememberMe = false;

  RegisterBloc({
    required this.initialChatServer,
  }) : super(RegisterInitial()) {
    on<RegisterRememberMeSwitched>(_onRegisterRememberMeSwitched);
    on<RegisterTapped>(_onRegisterTapped);

    _chatServerM = initialChatServer.copywith();

    _userApi = UserApi(serverUrl: initialChatServer.fullUrl);
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
  ) async {
    emit(RegisterInProgress());

    try {
      if (await _checkEmail(event.email)) {
      }
      // TODO: to next page with email and password in credential dto.
      else {
        emit(RegisterFailure(VoceAuthError.emailAlreadyExists));
      }
    } catch (e) {
      emit(RegisterFailure(VoceGeneralError.unknownError));
    }

    // TODO: Implement the registration logic,
    // emit RegisterSuccess() if the registration is successful,
    // emit RegisterFailure() if the registration fails.
  }

  Future<bool> _checkEmail(String email) async {
    try {
      return email.isEmail && await _userApi.checkEmailNew(email);
    } catch (e) {
      App.logger.severe(e);
      rethrow;
    }
  }
}
