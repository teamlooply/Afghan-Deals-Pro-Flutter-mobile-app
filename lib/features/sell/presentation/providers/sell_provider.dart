import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/auth/app_auth.dart';

// ── State ──────────────────────────────────────────────────────────────────────

class SellState {
  final List<XFile> images;
  final bool isSubmitting;
  final String? error;
  final bool success;
  final String? createdListingId;

  const SellState({
    this.images = const [],
    this.isSubmitting = false,
    this.error,
    this.success = false,
    this.createdListingId,
  });

  SellState copyWith({
    List<XFile>? images,
    bool? isSubmitting,
    String? error,
    bool? success,
    String? createdListingId,
  }) {
    return SellState(
      images: images ?? this.images,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      success: success ?? this.success,
      createdListingId: createdListingId ?? this.createdListingId,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class SellNotifier extends StateNotifier<SellState> {
  SellNotifier() : super(const SellState());

  final _picker = ImagePicker();
  final _client = Supabase.instance.client;

  static const int _maxImages = 10;

  // A phone camera hands back 4000px, multi-megabyte files. Stored originals
  // here already average ~880 kB and reach 14 MB, which is what makes listing
  // screens slow to load. 1600px is still more than any screen shows.
  static const double _maxUploadEdge = 1600;
  static const String _bucket = 'listing-images';

  // ── Image picking ────────────────────────────────────────────────────────────

  Future<void> pickFromGallery() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: _maxUploadEdge,
      maxHeight: _maxUploadEdge,
    );
    if (picked.isEmpty) return;
    final combined = [...state.images, ...picked];
    state = state.copyWith(
      images: combined.length > _maxImages
          ? combined.sublist(0, _maxImages)
          : combined,
    );
  }

  Future<void> pickFromCamera() async {
    if (state.images.length >= _maxImages) return;
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: _maxUploadEdge,
      maxHeight: _maxUploadEdge,
    );
    if (picked == null) return;
    state = state.copyWith(images: [...state.images, picked]);
  }

  void removeImage(int index) {
    final updated = [...state.images]..removeAt(index);
    state = state.copyWith(images: updated);
  }

  void reorderImages(int oldIndex, int newIndex) {
    final updated = [...state.images];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(images: updated);
  }

  // ── Upload ───────────────────────────────────────────────────────────────────

  Future<List<String>> _uploadImages(String listingId) async {
    final urls = <String>[];
    for (int i = 0; i < state.images.length; i++) {
      final file = File(state.images[i].path);
      final ext = state.images[i].path.split('.').last.toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final path = 'listings/$listingId/$i.$ext';

      await _client.storage.from(_bucket).upload(
        path,
        file,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );

      final url = _client.storage.from(_bucket).getPublicUrl(path);
      urls.add(url);
    }
    return urls;
  }

  // ── Create listing ───────────────────────────────────────────────────────────

  /// [customerPhone] posts the ad into a customer's own account instead of the
  /// poster's. Staff use it when they enter an ad for a walk-in: the customer
  /// later signs in with that number and finds the ad waiting for them, theirs
  /// to edit, delete and chat about.
  Future<void> createListing({
    required String category,
    required Map<String, dynamic> baseData,
    required Map<String, dynamic> categoryData,
    String? customerPhone,
    String? customerName,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null, success: false);

    try {
      final authUser = AppAuth.currentUserEntity;
      final userId = AppAuth.currentUserId;
      if (authUser == null || userId == null) {
        throw Exception('Please log in to post an ad');
      }
      final profileLookupValue = AppAuth.currentProfileLookupValue;
      final profileIdColumn = AppAuth.profileLookupColumn;

      // Fetch seller name from profiles
      final profile = await _client
          .from('profiles')
          .select('name')
          .eq(profileIdColumn, profileLookupValue ?? userId)
          .maybeSingle();
      final manualSellerName = (baseData['seller_name']?.toString() ?? '').trim();
      final normalizedCategory = category.trim().toLowerCase().replaceAll('_', '-');

      // Staff-entered ads belong to the customer and go live straight away;
      // everything else is the poster's own and waits for approval.
      String sellerId = userId;
      var goLiveNow = false;
      if (customerPhone != null && customerPhone.trim().isNotEmpty) {
        final resolved = await _client.rpc('staff_resolve_customer', params: {
          'p_phone': customerPhone.trim(),
          'p_name': (customerName ?? '').trim(),
        });
        sellerId = resolved.toString();
        goLiveNow = true;

        // Done here rather than in each of the four forms: the ad carries the
        // customer's name, and their number is what the WhatsApp button dials
        // unless the staff member typed a different one.
        final phone = customerPhone.trim();
        for (final key in ['whatsapp', 'phone', 'seller_phone']) {
          if ((categoryData[key]?.toString() ?? '').trim().isEmpty) {
            categoryData[key] = phone;
          }
        }
        if ((baseData['seller_name']?.toString() ?? '').trim().isEmpty &&
            (customerName ?? '').trim().isNotEmpty) {
          baseData['seller_name'] = customerName!.trim();
        }
      }

      final insertData = {
        ...baseData,
        'category': normalizedCategory,
        'category_data': categoryData,
        'seller_id': sellerId,
        'seller_name': manualSellerName.isNotEmpty
            ? manualSellerName
            : (profile?['name'] ?? ''),
        'country': baseData['country'] ?? 'Afghanistan',
        'images': <String>[],
        // User-posted listings stay pending until admin approval.
        'is_active': goLiveNow,
        'is_featured': false,
        'view_count': 0,
      };

      // Insert listing to get the ID
      final response = await _client
          .from('listings')
          .insert(insertData)
          .select('id')
          .single();
      final listingId = response['id'] as String;

      // Upload images and update listing
      if (state.images.isNotEmpty) {
        final imageUrls = await _uploadImages(listingId);
        await _client
            .from('listings')
            .update({'images': imageUrls})
            .eq('id', listingId);
      }

      state = state.copyWith(
        isSubmitting: false,
        success: true,
        createdListingId: listingId,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() => state = const SellState();
}

// ── Provider ───────────────────────────────────────────────────────────────────

final sellProvider =
    StateNotifierProvider.autoDispose<SellNotifier, SellState>(
  (ref) => SellNotifier(),
);
