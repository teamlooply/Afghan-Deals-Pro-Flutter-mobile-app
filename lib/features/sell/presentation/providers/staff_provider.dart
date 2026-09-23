import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether the signed-in user may post ads on a customer's behalf.
///
/// Answered by the database, which is also what enforces it, so the form can
/// never offer something the insert would then refuse.
final isStaffProvider = FutureProvider<bool>((ref) async {
  try {
    final result = await Supabase.instance.client.rpc('current_user_is_staff');
    return result == true;
  } catch (_) {
    return false;
  }
});
