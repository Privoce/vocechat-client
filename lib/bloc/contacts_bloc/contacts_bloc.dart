import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocechat_client/bloc/contacts_bloc/contacts_event.dart';
import 'package:vocechat_client/bloc/contacts_bloc/contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  ContactsBloc(super.initialState);
}
