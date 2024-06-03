import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/api/models/user/register_request.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/data/dto/login_credential_password_dto.dart';
import 'package:vocechat_client/data/dto/login_request_dto.dart';
import 'package:vocechat_client/extensions.dart';
import 'package:vocechat_client/util/error/voce_error.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final ChatServerM initialChatServer;

  late UserApi _userApi;

  bool _rememberMe = false;

  RegisterBloc({
    required this.initialChatServer,
  }) : super(RegisterInitial()) {
    on<RegisterRememberMeSwitched>(_onRegisterRememberMeSwitched);
    on<RegisterTapped>(_onRegisterTapped);
    on<RegisterUsernameContinueTapped>(_onRegisterUsernameContinueTapped);

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
        emit(RegisterToNextPage(
            email: event.email,
            password: event.password,
            rememberMe: _rememberMe));
      } else {
        emit(RegisterFailure(VoceAuthError.emailAlreadyExists));
      }
    } on DioException catch (e) {
      App.logger.severe(e);
      emit(RegisterFailure(VoceNetworkError.networkError));
    } catch (e) {
      emit(RegisterFailure(VoceGeneralError.unknownError));
    }
  }

  void _onRegisterUsernameContinueTapped(
    RegisterUsernameContinueTapped event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterInProgress());

    try {
      // final RegisterRequest
    } on DioException catch (e) {
      App.logger.severe(e);
      emit(RegisterFailure(VoceNetworkError.networkError));
    } catch (e) {
      emit(RegisterFailure(VoceGeneralError.unknownError));
    }
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
