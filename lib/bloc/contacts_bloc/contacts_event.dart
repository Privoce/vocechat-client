abstract class ContactsEvent {}

class ContactsInitialLoad extends ContactsEvent {
  final bool isContactVerificationEnabled;

  ContactsInitialLoad({required this.isContactVerificationEnabled});
}
