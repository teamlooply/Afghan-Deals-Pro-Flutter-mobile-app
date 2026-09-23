import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/widgets/favorite_button.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../chat/presentation/providers/chat_provider.dart';
import '../providers/spare_parts_provider.dart';
import '../../../../../core/utils/image_url.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/utils/phone_call.dart';
import '../../../../../core/utils/whatsapp.dart';

const _kBlue = Color(0xFF2258A8);

class SparePartsDetailScreen extends ConsumerStatefulWidget {
  final SparePartListing listing;
  const SparePartsDetailScreen({super.key, required this.listing});

  @override
  ConsumerState<SparePartsDetailScreen> createState() =>
      _SparePartsDetailScreenState();
}

class _SparePartsDetailScreenState
    extends ConsumerState<SparePartsDetailScreen> {
  late final PageController _pageController;
  final MapController _mapController = MapController();
  Timer? _timer;
  int _currentPage = 0;
  LatLng? _latLng;
  bool _geocoding = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    if (widget.listing.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % widget.listing.images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      });
    }
    _geocode();
  }

  Future<void> _geocode() async {
    final query = widget.listing.location;
    try {
      final client = HttpClient();
      final req = await client.getUrl(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
        ),
      );
      req.headers.set('User-Agent', 'AfghanDealsPro/1.0');
      final res = await req.close();
      final body = await res.transform(const Utf8Decoder()).join();
      final list = jsonDecode(body) as List<dynamic>;
      if (list.isNotEmpty) {
        final lat = double.tryParse(list[0]['lat']?.toString() ?? '');
        final lon = double.tryParse(list[0]['lon']?.toString() ?? '');
        if (lat != null && lon != null && mounted) {
          setState(() => _latLng = LatLng(lat, lon));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _geocoding = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.listing;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            children: [
              Expanded(
                  child: _actionButton(Icons.phone_outlined, 'Call',
                      () => _launchCall(item.phone))),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  FontAwesomeIcons.whatsapp,
                  '',
                  () => _launchWhatsApp(item.phone),
                  isFa: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: _actionButton(
                      Icons.message_outlined, 'Chat', () => _openChat(item))),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 312,
                    width: double.infinity,
                    child: item.images.isEmpty
                        ? Container(
                            color: const Color(0xFFE8E8E8),
                            child: const Icon(Icons.build_outlined,
                                size: 50, color: Colors.grey),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: item.images.length,
                            onPageChanged: (index) =>
                                setState(() => _currentPage = index),
                            itemBuilder: (_, i) => Image(image: CachedNetworkImageProvider(fullImageUrl(item.images[i])),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE8E8E8),
                                child: const Icon(Icons.build_outlined,
                                    size: 50, color: Colors.grey),
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 12, color: Colors.black87),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x63000000),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentPage + 1}/${item.images.isEmpty ? 1 : item.images.length}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (item.images.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          item.images.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: index == _currentPage ? 10 : 7,
                            height: index == _currentPage ? 10 : 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD9D9D9),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -14),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _circleButton(
                                icon: Icons.reply_outlined, onTap: _shareItem),
                            const SizedBox(width: 10),
                            FavoriteButton(listingId: item.id, size: 36),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      'Name',
                      style: GoogleFonts.poppins(
                        fontSize: 36 / 2,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.year.isEmpty ? '-' : item.year}, ${item.make.isEmpty ? 'Spare Parts' : item.make}',
                      style: GoogleFonts.poppins(
                        fontSize: 34 / 2,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 20, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location,
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 160,
                        child: _geocoding
                            ? Container(
                                color: const Color(0xFFDCE8F6),
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              )
                            : _latLng == null
                                ? GestureDetector(
                                    onTap: () => _openMap(item),
                                    child: Container(
                                      color: const Color(0xFFDCE8F6),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.location_on_outlined,
                                                size: 40,
                                                color: _kBlue.withValues(
                                                    alpha: 0.8)),
                                            const SizedBox(height: 6),
                                            Text('Tap to open map',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: _kBlue)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () => _openMap(item),
                                    child: FlutterMap(
                                      mapController: _mapController,
                                      options: MapOptions(
                                        initialCenter: _latLng!,
                                        initialZoom: 14,
                                        interactionOptions:
                                            const InteractionOptions(
                                          flags: InteractiveFlag.none,
                                        ),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName:
                                              'com.afghandeals.afghan_deals_pro',
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: _latLng!,
                                              width: 40,
                                              height: 40,
                                              child: const Icon(
                                                Icons.location_on,
                                                color: Colors.red,
                                                size: 40,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _workingHoursCard(item.workingHours),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workingHoursCard(List<SparePartWorkingHour> hours) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCFCFCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Text(
              'Working Hours',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text('Days',
                      style: GoogleFonts.poppins(
                          fontSize: 17, fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: Text('Morning',
                      style: GoogleFonts.poppins(
                          fontSize: 17, fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: Text('Evening',
                      style: GoogleFonts.poppins(
                          fontSize: 17, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8E9EB)),
          ...hours.map(
            (h) => Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(h.day,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: const Color(0xFF666666))),
                  ),
                  Expanded(
                    child: Text(h.morning,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: const Color(0xFF666666))),
                  ),
                  Expanded(
                    child: Text(h.evening,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: const Color(0xFF666666))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    dynamic icon,
    String label,
    VoidCallback onTap, {
    bool isFa = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isFa)
              FaIcon(icon as FaIconData, size: 16, color: _kBlue)
            else
              Icon(icon as IconData, size: 16, color: _kBlue),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchCall(String phone) => openPhoneCall(context, phone);

  Future<void> _launchWhatsApp(String phone) => openWhatsApp(context, phone);

  Future<void> _openMap(SparePartListing item) async {
    final mapUrl = item.mapUrl;
    if (mapUrl.isNotEmpty) {
      await launchUrl(Uri.parse(mapUrl), mode: LaunchMode.externalApplication);
      return;
    }

    final query = Uri.encodeComponent(item.location);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _openChat(SparePartListing item) async {
    try {
      final chatId =
          await ref.read(chatActionsProvider).openOrCreateChatForListing(
                listingId: item.id,
                sellerId: item.sellerId,
              );
      if (!mounted) return;
      context.push('/chat/$chatId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareItem() {
    final itemName = widget.listing.title;
    final shareText =
        'Check out this spare part: $itemName on Afghan Deals Pro';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.t('share_listing'),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.copy, color: Color(0xFF2258A8)),
                title: Text(context.l10n.t('copy_to_clipboard'),
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: shareText));
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.t('copied_text').replaceAll('{text}', itemName)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Color(0xFF2258A8)),
                title: Text(context.l10n.t('share_via_message'),
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${context.l10n.t('shared')}: $itemName'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: Color(0xFF2258A8)),
                title:
                    Text(context.l10n.t('copy_link'), style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                        text:
                            'afghan-deals-pro://spare-parts/${widget.listing.id}'),
                  );
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.t('link_copied').replaceAll('{text}', itemName)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton(
      {required IconData icon,
      Color color = Colors.black87,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x30000000), blurRadius: 4)],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
