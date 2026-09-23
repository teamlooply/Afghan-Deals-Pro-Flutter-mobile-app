import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/favorite_button.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/translated_text.dart';
import '../../../../chat/presentation/providers/chat_provider.dart';
import '../../../../../features/listings/data/models/car_sale_model.dart';
import '../../../../../core/utils/image_url.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/utils/phone_call.dart';

class CarSaleDetailScreen extends ConsumerStatefulWidget {
  final CarSaleModel car;
  const CarSaleDetailScreen({super.key, required this.car});

  @override
  ConsumerState<CarSaleDetailScreen> createState() =>
      _CarSaleDetailScreenState();
}

class _CarSaleDetailScreenState extends ConsumerState<CarSaleDetailScreen> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  String _sellerPhone = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _sellerPhone = widget.car.phone;
    _loadSellerPhone();
    if (widget.car.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % widget.car.images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentPage = next);
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
    final car = widget.car;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
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
                    child: car.images.isEmpty
                        ? Container(
                            color: const Color(0xFFE8E8E8),
                            child: const Icon(Icons.directions_car,
                                size: 50, color: Colors.grey),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: car.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemBuilder: (_, i) => Image(image: CachedNetworkImageProvider(fullImageUrl(car.images[i])),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE8E8E8),
                                child: const Icon(Icons.directions_car,
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
                            '${_currentPage + 1}/${car.images.isEmpty ? 1 : car.images.length}',
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
                  if (car.images.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          car.images.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
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
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
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
                            _circleButton(icon: Icons.reply_outlined, onTap: _shareItem),
                            const SizedBox(width: 10),
                            FavoriteButton(listingId: car.id, size: 36),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      car.formattedPrice,
                      style: GoogleFonts.poppins(
                        fontSize: 17.88,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 24.24 / 17.88,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TranslatedText(
                      car.title,
                      style: GoogleFonts.poppins(
                        fontSize: 17.24,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF141414),
                        height: 31.04 / 17.24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _DetailSpec(
                            icon: Icons.calendar_month_outlined,
                            value: car.year.isEmpty ? '-' : car.year),
                        const SizedBox(width: 14),
                        _DetailSpec(
                            icon: Icons.speed_outlined,
                            value: car.mileage.isEmpty ? '-' : car.mileage),
                        const SizedBox(width: 14),
                        _DetailSpec(
                            icon: Icons.public,
                            value: car.transmission.isEmpty
                                ? '-'
                                : car.transmission),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: Color(0xFF505050)),
                        const SizedBox(width: 5),
                        TranslatedText(
                          car.location.isNotEmpty
                              ? car.location
                              : context.l10n.t('afghanistan'),
                          style: GoogleFonts.poppins(
                            fontSize: 11.62,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF505050),
                            height: 17.06 / 11.62,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.t('car_overview'),
                      style: GoogleFonts.poppins(
                        fontSize: 19.06,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 31.04 / 19.06,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _overviewRow(context.l10n.t('Condition'),
                        car.condition.isEmpty ? '-' : car.condition),
                    _overviewRow(
                        context.l10n.t('Body Type'), car.bodyType.isEmpty ? '-' : car.bodyType),
                    _overviewRow(
                        context.l10n.t('Fuel Type'), car.fuelType.isEmpty ? '-' : car.fuelType),
                    _overviewRow(context.l10n.t('Transmission'),
                        car.transmission.isEmpty ? '-' : car.transmission),
                    _overviewRow(context.l10n.t('exterior_color'),
                        car.color.isEmpty ? '-' : car.color),
                    _overviewRow(context.l10n.t('interior_color'),
                        car.interiorColor.isEmpty ? '-' : car.interiorColor),
                    _overviewRow(context.l10n.t('regional_specs'),
                        car.regionalSpecs.isEmpty ? '-' : car.regionalSpecs),
                    const SizedBox(height: 14),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _detailAction(Icons.phone_outlined, context.l10n.t('call'),
                            onTap: () => openPhoneCall(context, _sellerPhone))),
                        const SizedBox(width: 8),
                        Expanded(child: _whatsAppAction(onTap: _openWhatsApp)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareItem() {
    final itemName = widget.car.title;
    final shareText = context.l10n.t('check_out_listing')
        .replaceAll('{text}', itemName)
        .replaceAll('{price}', widget.car.formattedPrice);

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
                title: Text(context.l10n.t('copy_link'),
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: 'afghan-deals-pro://car-detail/${widget.car.id}'),
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

  Widget _circleButton({required IconData icon, Color color = Colors.black87, required VoidCallback onTap}) {
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Car ads don't carry their own contact number, so WhatsApp uses the number
  // on the seller's profile.
  Future<void> _loadSellerPhone() async {
    if (_sellerPhone.trim().isNotEmpty) return;
    final sellerId = widget.car.sellerId.trim();
    if (sellerId.isEmpty) return;
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('phone')
          .eq('id', sellerId)
          .maybeSingle();
      final phone = row?['phone']?.toString() ?? '';
      if (mounted && phone.trim().isNotEmpty) {
        setState(() => _sellerPhone = phone);
      }
    } catch (_) {
      // Leave the button to fall back to in-app chat.
    }
  }

  Future<void> _openWhatsApp() async {
    final digits = _sellerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.t('seller_no_whatsapp')),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final uri = Uri.parse('https://wa.me/$digits');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.t('whatsapp_not_installed')),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _openChat() async {
    try {
      final chatId =
          await ref.read(chatActionsProvider).openOrCreateChatForListing(
                listingId: widget.car.id,
                sellerId: widget.car.sellerId,
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

  Widget _detailAction(IconData icon, String label, {VoidCallback? onTap}) {
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
            Icon(icon, size: 16, color: const Color(0xFF2258A8)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.24,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 25.12 / 14.24,
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
}

class _DetailSpec extends StatelessWidget {
  final IconData icon;
  final String value;
  const _DetailSpec({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF505050)),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14.24,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF505050),
            height: 25.12 / 14.24,
          ),
        ),
      ],
    );
  }
}
