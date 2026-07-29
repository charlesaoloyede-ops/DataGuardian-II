import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../../../services/security/pin_service.dart';
import '../../../services/storage/shared_prefs_service.dart';
import '../data/topup_api_client.dart';
import '../domain/entities/beneficiary.dart';
import '../domain/entities/data_plan.dart';
import '../domain/entities/initiate_result.dart';
import '../domain/entities/network_provider.dart';
import '../domain/entities/purchase_type.dart';
import '../domain/i_topup_repository.dart';
import 'format.dart';
import 'providers/topup_providers.dart';
import 'screens/checkout_webview_screen.dart';
import 'screens/purchase_status_screen.dart';
import 'widgets/topup_sheets.dart';

/// Shared checkout orchestration for both airtime and data:
/// confirm → authorise (PIN) → save beneficiary → initiate → checkout → status.
Future<void> runPurchaseFlow(
  BuildContext context,
  WidgetRef ref, {
  required PurchaseType type,
  required NetworkProvider network,
  required String phone,
  int? amount,
  DataPlan? plan,
  String? contactName,
}) async {
  final payAmount = type == PurchaseType.data ? plan!.price : amount!;

  final confirmed = await showConfirmSheet(
    context,
    heading: 'Confirm ${type.label.toLowerCase()} purchase',
    rows: [
      ('Type', type == PurchaseType.data ? plan!.name : 'Airtime'),
      ('Network', network.label),
      ('Recipient', phone),
      ('You pay', naira(payAmount)),
    ],
    payLabel: 'Pay ${naira(payAmount)}',
  );
  if (!confirmed || !context.mounted) return;

  // Authorise: require PIN if one is set; otherwise offer to set one up once.
  final pin = getIt<PinService>();
  if (await pin.hasPin()) {
    if (!context.mounted) return;
    final ok = await authorizeWithPin(context);
    if (!ok) return;
  } else {
    if (!context.mounted) return;
    await _maybeOfferPinSetup(context);
  }
  if (!context.mounted) return;

  // Remember this recipient for next time.
  await ref.read(beneficiariesProvider.notifier).save(
        Beneficiary(
          phone: phone,
          network: network,
          name: contactName,
          lastUsed: DateTime.now(),
        ),
      );
  if (!context.mounted) return;

  // Start the purchase (creates the Paystack checkout).
  InitiateResult res;
  try {
    res = await _withLoading(
      context,
      () => getIt<ITopUpRepository>().initiate(
        type: type,
        network: network,
        phone: phone,
        amount: type == PurchaseType.airtime ? amount : null,
        variationCode: type == PurchaseType.data ? plan!.variationCode : null,
      ),
    );
  } on TopUpException catch (e) {
    if (context.mounted) _snack(context, e.message);
    return;
  } catch (_) {
    if (context.mounted) _snack(context, 'Something went wrong. Please try again.');
    return;
  }
  if (!context.mounted) return;

  // Open Paystack checkout, then show live status (regardless of how the
  // webview closed — the status screen reflects the true state).
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => CheckoutWebViewScreen(authorizationUrl: res.authorizationUrl),
  ));
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => PurchaseStatusScreen(reference: res.reference),
  ));
}

Future<void> _maybeOfferPinSetup(BuildContext context) async {
  final prefs = getIt<SharedPrefsService>();
  if (prefs.pinSetupOffered) return;
  await prefs.setPinSetupOffered(true);
  if (!context.mounted) return;
  final set = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Secure your purchases?'),
      content: const Text(
          'Set a 4-digit transaction PIN to confirm future top-ups. You can also do this later in Settings.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now')),
        FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Set PIN')),
      ],
    ),
  );
  if (set == true && context.mounted) {
    await showPinSetupSheet(context);
  }
}

Future<T> _withLoading<T>(
    BuildContext context, Future<T> Function() action) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    return await action();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

void _snack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}
