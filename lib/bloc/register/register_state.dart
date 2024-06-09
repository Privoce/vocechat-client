part of 'register_bloc.dart';

abstract class RegisterState extends Equatable {
  const RegisterState();

  @override
  List<Object> get props => [];
}

class RegisterInitial extends RegisterState {}

class RegisterNoFcmToken extends RegisterState {}

class RegisterInProgress extends RegisterState {}

class RegisterToNextPage extends RegisterState {
  final String email;
  final String password;
  final bool rememberMe;

  const RegisterToNextPage({
    required this.email,
    required this.password,
    required this.rememberMe,
  });

  @override
  List<Object> get props => [email, password, rememberMe];
}

class RegisterFailure extends RegisterState {
  final String error;

  const RegisterFailure(this.error);

  @override
  List<Object> get props => [error];
}
