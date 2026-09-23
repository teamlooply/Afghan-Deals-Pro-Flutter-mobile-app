import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_localizations.dart';

/// Staff-only: enter an ad for a walk-in customer.
///
/// The ad is created in the customer's own account, found or created from their
/// phone number, so when they later sign in with that number the ad is already
/// theirs to edit, delete and answer chats on.
class CustomerPostingSection extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final TextEditingController nameController;
  final TextEditingController phoneController;

  const CustomerPostingSection({
    super.key,
    required this.enabled,
    required this.onChanged,
    required this.nameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.t('Post for a customer'),
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
          Text(l10n.t('The ad goes into the customer account for this number.'),
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
          if (enabled) ...[
            const SizedBox(height: 12),
            _field(l10n.t('Customer Name'), nameController,
                l10n.t('e.g. Ahmed Khan')),
            const SizedBox(height: 12),
            _field(l10n.t('Customer WhatsApp Number'), phoneController,
                l10n.t('e.g. +93 70 123 4567'),
                keyboardType: TextInputType.phone),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2258A8)),
            ),
          ),
        ),
      ],
    );
  }
}
