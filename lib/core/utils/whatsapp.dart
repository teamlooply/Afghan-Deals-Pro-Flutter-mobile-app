import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';

/// Opens a WhatsApp chat with [phone].
///
/// Every listing detail screen used to wire its WhatsApp button differently:
/// some opened the in-app chat instead, and the rest opened WhatsApp with an
/// empty number when the seller had not given one. Only 2 of 35 live ads carry
/// a number, so the empty case is the common one and needs a clear message.
Future<void> openWhatsApp(BuildContext context, String? phone) async {
  final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;

  void tell(String key) => messenger.showSnackBar(SnackBar(
        content: Text(l10n.t(key)),
        behavior: SnackBarBehavior.floating,
      ));

  if (digits.isEmpty) {
    tell('seller_no_whatsapp');
    return;
  }
  final opened = await launchUrl(Uri.parse('https://wa.me/$digits'),
      mode: LaunchMode.externalApplication);
  if (!opened) tell('whatsapp_not_installed');
}
