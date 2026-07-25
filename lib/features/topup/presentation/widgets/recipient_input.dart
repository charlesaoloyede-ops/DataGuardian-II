import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/phone_utils.dart';
import '../providers/topup_providers.dart';

/// Phone-number field with a contact picker and quick-select chips for saved
/// recipients.
class RecipientInput extends ConsumerWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// Called with a contact's display name when one is picked (so the caller can
  /// save it as the beneficiary label). Null for manual entry.
  final ValueChanged<String?>? onName;

  const RecipientInput({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beneficiaries = ref.watch(beneficiariesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            LengthLimitingTextInputFormatter(14),
          ],
          onChanged: (v) {
            onName?.call(null); // manual edit clears any picked contact name
            onChanged(v);
          },
          decoration: InputDecoration(
            labelText: 'Phone number',
            hintText: '0803 000 0000',
            prefixIcon: const Icon(Icons.phone_outlined),
            suffixIcon: IconButton(
              tooltip: 'Pick from contacts',
              icon: const Icon(Icons.contacts_outlined),
              onPressed: () => _pickContact(context),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        if (beneficiaries.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Recent', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in beneficiaries)
                InputChip(
                  avatar: const Icon(Icons.person_outline, size: 18),
                  label: Text(b.name?.isNotEmpty == true ? b.name! : b.phone),
                  onPressed: () {
                    controller.text = b.phone;
                    onName?.call(b.name);
                    onChanged(b.phone);
                  },
                  onDeleted: () =>
                      ref.read(beneficiariesProvider.notifier).remove(b.phone),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _pickContact(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Contacts permission denied. You can type the number instead.')));
        return;
      }
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;
      final full = contact.phones.isNotEmpty
          ? contact
          : await FlutterContacts.getContact(contact.id, withProperties: true);
      final phones = full?.phones ?? const [];
      if (phones.isEmpty) {
        messenger.showSnackBar(const SnackBar(
            content: Text('That contact has no phone number.')));
        return;
      }
      final normalized = PhoneUtils.normalize(phones.first.number);
      controller.text = normalized;
      onName?.call(full?.displayName);
      onChanged(normalized);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Couldn\'t open contacts. You can type the number instead.')));
    }
  }
}
