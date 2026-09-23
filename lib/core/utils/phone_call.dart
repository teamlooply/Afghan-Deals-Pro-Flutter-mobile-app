import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';

/// Dials [phone], or says plainly that the seller left no number.
///
/// Mirrors [openWhatsApp]: the old buttons built a `tel:` link straight from the
/// listing, so an ad without a number opened the dialer empty.
Future<void> openPhoneCall(BuildContext context, String? phone) async {
  final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;

  void tell(String key) => messenger.showSnackBar(SnackBar(
        content: Text(l10n.t(key)),
        behavior: SnackBarBehavior.floating,
      ));

  if (digits.replaceAll('+', '').isEmpty) {
    tell('seller_no_phone');
    return;
  }
  if (!await launchUrl(Uri.parse('tel:$digits'),
      mode: LaunchMode.externalApplication)) {
    tell('cannot_place_call');
  }
}
