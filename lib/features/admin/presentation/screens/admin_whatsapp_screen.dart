import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lets an admin give a WhatsApp number to sellers who posted without one.
///
/// Numbers are set per seller, not per ad: one entry fills every one of that
/// seller's ads that has no number yet, and never overwrites a number the
/// seller typed themselves. Both calls are admin-only RPCs, so this keeps
/// working once listing writes are locked down to their owners.
class AdminWhatsAppScreen extends StatefulWidget {
  const AdminWhatsAppScreen({super.key});

  @override
  State<AdminWhatsAppScreen> createState() => _AdminWhatsAppScreenState();
}

class _SellerRow {
  final String sellerId;
  final String name;
  final int missing;
  final int total;
  final TextEditingController controller = TextEditingController();
  bool saving = false;

  _SellerRow(this.sellerId, this.name, this.missing, this.total);
}

class _AdminWhatsAppScreenState extends State<AdminWhatsAppScreen> {
  final _client = Supabase.instance.client;
  late Future<List<_SellerRow>> _rows = _load();

  Future<List<_SellerRow>> _load() async {
    final data = await _client.rpc('admin_sellers_missing_whatsapp') as List;
    return [
      for (final r in data)
        _SellerRow(
          r['seller_id'].toString(),
          (r['seller_name'] ?? '').toString().trim().isEmpty
              ? 'Unnamed seller'
              : r['seller_name'].toString(),
          (r['missing'] as num).toInt(),
          (r['total'] as num).toInt(),
        ),
    ];
  }

  Future<void> _save(_SellerRow row) async {
    final digits = row.controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9 || digits.length > 15) {
      _toast('Enter the number with country code, e.g. +93 70 123 4567');
      return;
    }
    setState(() => row.saving = true);
    try {
      final updated = await _client.rpc('admin_set_seller_whatsapp', params: {
        'p_seller_id': row.sellerId,
        'p_phone': row.controller.text.trim(),
      });
      _toast('WhatsApp added to $updated ad(s) for ${row.name}');
      setState(() => _rows = _load());
    } catch (e) {
      _toast('Could not save: $e');
      if (mounted) setState(() => row.saving = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text('WhatsApp Numbers',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder<List<_SellerRow>>(
        future: _rows,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load sellers.\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.black54)),
              ),
            );
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return Center(
              child: Text('Every live ad has a WhatsApp number.',
                  style: GoogleFonts.poppins(color: Colors.black54)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _rows = _load()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Text(
                    '${rows.length} seller(s) have ads without a WhatsApp '
                    'number. A number saved here is added to all of that '
                    "seller's ads that are missing one.",
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.black54),
                  );
                }
                return _SellerCard(row: rows[i - 1], onSave: _save);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  final _SellerRow row;
  final Future<void> Function(_SellerRow) onSave;

  const _SellerCard({required this.row, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.name,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${row.missing} of ${row.total} ad(s) missing a number',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+93 70 123 4567',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: row.saving ? null : () => onSave(row),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                  ),
                  child: row.saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
