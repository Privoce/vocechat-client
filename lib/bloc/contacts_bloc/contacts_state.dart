import 'package:equatable/equatable.dart';

abstract class ContactsState extends Equatable {}

class ContactInitial extends ContactsState {
  @override
  List<Object?> get props => [];
}

class ContactsLoadSuccess extends ContactsState {
  final List<String> contacts;

  ContactsLoadSuccess({required this.contacts});

  @override
  List<Object?> get props => [contacts];
}

class ContactsUpdated extends ContactsState {
  final List<String> contacts;

  ContactsUpdated({required this.contacts});

  @override
  List<Object?> get props => [contacts];
}
