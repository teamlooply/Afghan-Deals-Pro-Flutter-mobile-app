import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/favorite_button.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/translated_text.dart';
import '../../../../chat/presentation/providers/chat_provider.dart';
import '../../../../../features/listings/data/models/mobile_listing_model.dart';
import '../../../../../core/utils/image_url.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/utils/whatsapp.dart';
import '../../../../../core/utils/phone_call.dart';

class MobileDetailScreen extends ConsumerStatefulWidget {
  final MobileListingModel mobile;
  const MobileDetailScreen({super.key, required this.mobile});

  @override
  ConsumerState<MobileDetailScreen> createState() => _MobileDetailScreenState();
}

class _MobileDetailScreenState extends ConsumerState<MobileDetailScreen> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentImage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    if (widget.mobile.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentImage + 1) % widget.mobile.images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentImage = next);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = widget.mobile;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed top image section with back button, image counter, and dots
            Stack(
              children: [
                SizedBox(
                  height: 312,
                  width: double.infinity,
                  child: mobile.images.isEmpty
                      ? Container(
                          color: const Color(0xFFE8E8E8),
                          child: const Icon(Icons.smartphone,
                              size: 50, color: Colors.grey),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: mobile.images.length,
                          onPageChanged: (i) =>
                              setState(() => _currentImage = i),
                          itemBuilder: (_, i) => Image(image: CachedNetworkImageProvider(fullImageUrl(mobile.images[i])),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFE8E8E8),
                              child: const Icon(Icons.smartphone,
                                  size: 50, color: Colors.grey),
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 21,
                      height: 21,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          '${_currentImage + 1}/${mobile.images.isEmpty ? 1 : mobile.images.length}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11.62,
                            fontWeight: FontWeight.w400,
                            height: 17.06 / 11.62,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (mobile.images.length > 1)
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        mobile.images.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: index == _currentImage ? 10 : 7,
                          height: index == _currentImage ? 10 : 7,
                          decoration: BoxDecoration(
                            color: index == _currentImage
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Fixed header section (title, category, location) with share/favorite buttons
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
                          FavoriteButton(listingId: mobile.id, size: 36),
                        ],
                      ),
                    ),
                  ),
                  TranslatedText(
                    mobile.title,
                    style: GoogleFonts.poppins(
                      fontSize: 17.24,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF141414),
                      height: 31.04 / 17.24,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TranslatedText(
                    mobile.subcategory.isNotEmpty
                        ? '${context.l10n.t('category_mobiles')} / ${mobile.subcategory}'
                        : context.l10n.t('category_mobiles'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: Color(0xFF505050)),
                      const SizedBox(width: 5),
                      TranslatedText(
                        mobile.location,
                        style: GoogleFonts.poppins(
                          fontSize: 11.62,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF505050),
                          height: 17.06 / 11.62,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Scrollable details content
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(
                          height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                      const SizedBox(height: 14),
                      if (mobile.description.isNotEmpty)
                        TranslatedText(
                          mobile.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF141414),
                            height: 1.6,
                          ),
                        ),
                      if (mobile.description.isNotEmpty)
                        const SizedBox(height: 14),
                      if (mobile.description.isNotEmpty)
                        const Divider(
                            height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                      if (mobile.description.isNotEmpty)
                        const SizedBox(height: 14),
                      if (mobile.brand.isNotEmpty)
                        _overviewRow(context.l10n.t('Brand'), mobile.brand),
                      if (mobile.model.isNotEmpty)
                        _overviewRow(context.l10n.t('Model'), mobile.model),
                      if (mobile.storage.isNotEmpty)
                        _overviewRow(context.l10n.t('Storage'), mobile.storage),
                      if (mobile.color.isNotEmpty)
                        _overviewRow(context.l10n.t('Color'), mobile.color),
                      if (mobile.condition.isNotEmpty)
                        _overviewRow(context.l10n.t('Condition'), mobile.condition),
                      if (mobile.age.isNotEmpty)
                        _overviewRow(context.l10n.t('Age'), mobile.age),
                      if (mobile.warranty.isNotEmpty)
                        _overviewRow(context.l10n.t('Warranty'), mobile.warranty),
                      if (mobile.batteryHealth.isNotEmpty)
                        _overviewRow(context.l10n.t('Battery Health'), mobile.batteryHealth),
                      if (mobile.version.isNotEmpty)
                        _overviewRow(context.l10n.t('Version'), mobile.version),
                      if (mobile.damageDetails.isNotEmpty)
                        _overviewRow(context.l10n.t('Damage / Defects'), mobile.damageDetails),
                      if (mobile.screenSize.isNotEmpty)
                        _overviewRow(context.l10n.t('Screen Size'), mobile.screenSize),
                      _overviewRow('Posted', mobile.formattedDate),
                      const SizedBox(height: 14),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    ],
                  ),
                ),
              ),
            ),
            // Fixed bottom action buttons
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Row(
                children: [
                  Expanded(
                      child: _detailAction(Icons.phone_outlined, context.l10n.t('call'),
                          onTap: () => openPhoneCall(context, mobile.phone))),
                  const SizedBox(width: 8),
                  Expanded(child: _whatsAppAction(onTap: () => openWhatsApp(context, mobile.phone))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TranslatedText(
              k,
              style: GoogleFonts.poppins(
                fontSize: 17.24,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 25.12 / 17.24,
                letterSpacing: 0,
              ),
            ),
          ),
          SizedBox(
            width: 132,
            child: TranslatedText(
              v,
              textAlign: TextAlign.left,
              style: GoogleFonts.poppins(
                fontSize: 17.24,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 25.12 / 17.24,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareItem() {
    final itemName = widget.mobile.title;
    final shareText =
        'Check out this mobile: $itemName - ${widget.mobile.formattedPrice} on Afghan Deals Pro';

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
                  Navigator.pop(context);
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
                  Navigator.pop(context);
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
                        text: 'afghan-deals-pro://mobile/${widget.mobile.id}'),
                  );
                  Navigator.pop(context);
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

  Widget _detailAction(IconData icon, String? label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          color: Colors.white,
        ),
        child: label == null
            ? Center(
                child: Icon(icon, size: 18, color: const Color(0xFF2258A8)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: const Color(0xFF2258A8)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14.24,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      height: 25.12 / 14.24,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _whatsAppAction({VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          color: Colors.white,
        ),
        child: const Center(
          child: FaIcon(
            FontAwesomeIcons.whatsapp,
            size: 16,
            color: Color(0xFF2258A8),
          ),
        ),
      ),
    );
  }

  Future<void> _openChat() async {
    try {
      final chatId =
          await ref.read(chatActionsProvider).openOrCreateChatForListing(
                listingId: widget.mobile.id,
                sellerId: widget.mobile.sellerId,
                sellerName: widget.mobile.sellerName,
                sellerPhone: widget.mobile.phone,
              );
      if (!mounted) return;
      context.push('/chat/$chatId');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      if (message.toLowerCase().contains('please sign in first')) {
        context.push(RouteNames.onboarding);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri);
  }
}
