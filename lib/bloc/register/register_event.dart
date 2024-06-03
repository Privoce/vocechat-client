part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object> get props => [];
}

class RegisterRememberMeSwitched extends RegisterEvent {
  final bool rememberMe;

  const RegisterRememberMeSwitched(this.rememberMe);

  @override
  List<Object> get props => [rememberMe];
}

class RegisterTapped extends RegisterEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const RegisterTapped({
    required this.email,
    required this.password,
    required this.rememberMe,
  });

  @override
  List<Object> get props => [email, password];
}

class RegisterUsernameContinueTapped extends RegisterEvent {
  final String email;
  final String password;
  final String username;
  final bool rememberMe;

  const RegisterUsernameContinueTapped({
    required this.email,
    required this.password,
    required this.username,
    required this.rememberMe,
  });

  @override
  List<Object> get props => [username];
}
