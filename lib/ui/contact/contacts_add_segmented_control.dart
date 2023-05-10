import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum ContactSearchType { id, email }

class ContactsAddSegmentedControl extends StatefulWidget
    implements PreferredSizeWidget {
  final ValueNotifier<ContactSearchType> typeNotifier;

  const ContactsAddSegmentedControl({required this.typeNotifier, Key? key})
      : super(key: key);

  @override
  State<ContactsAddSegmentedControl> createState() =>
      _ContactsAddSegmentedControlState();

  @override
  Size get preferredSize => const Size(double.maxFinite, 40.0);
}

class _ContactsAddSegmentedControlState
    extends State<ContactsAddSegmentedControl> {
  ContactSearchType type = ContactSearchType.id;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CupertinoSegmentedControl<ContactSearchType>(
          children: <ContactSearchType, Widget>{
            ContactSearchType.id:
                _buildOptionButton(AppLocalizations.of(context)!.userId),
            ContactSearchType.email:
                _buildOptionButton(AppLocalizations.of(context)!.userEmail)
          },
          onValueChanged: (ContactSearchType? value) {
            if (value != null) {
              setState(() {
                type = value;
              });
              widget.typeNotifier.value = value;
            }
          },
          groupValue: type),
    );
  }

  Widget _buildOptionButton(String text) {
    final maxWidth = (MediaQuery.of(context).size.width - 16) / 2;
    return Container(
      constraints: BoxConstraints(minWidth: 60, maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
