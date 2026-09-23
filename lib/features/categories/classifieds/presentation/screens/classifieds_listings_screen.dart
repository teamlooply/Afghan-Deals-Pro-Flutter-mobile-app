import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/localized_lookup.dart';
import '../../../../../core/widgets/favorite_button.dart';
import '../../../../../core/widgets/translated_text.dart';
import '../providers/classifieds_provider.dart';
import '../../../../../features/listings/data/models/classified_listing_model.dart';
import 'classifieds_detail_screen.dart';
import 'classifieds_filter_screen.dart';
import '../../../../../core/utils/image_url.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/utils/phone_call.dart';
import '../../../../../core/utils/whatsapp.dart';

const _kBlue = Color(0xFF2258A8);

class ClassifiedsListingsScreen extends ConsumerStatefulWidget {
  final String subcategory;
  final String subcategoryLabel;
  const ClassifiedsListingsScreen({
    super.key,
    required this.subcategory,
    required this.subcategoryLabel,
  });

  @override
  ConsumerState<ClassifiedsListingsScreen> createState() =>
      _ClassifiedsListingsScreenState();
}

class _ClassifiedsListingsScreenState
    extends ConsumerState<ClassifiedsListingsScreen> {
  String _sortLabel(BuildContext context, String value) =>
      localizedCarSortLabel(context.l10n, value);

  @override
  Widget build(BuildContext context) {
    final listingsAsync =
        ref.watch(classifiedsFilteredProvider(widget.subcategory));
    final filter = ref.watch(classifiedsFilterProvider);
    final hasFilter = !filter.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.black87),
        ),
        title: Text(
          widget.subcategoryLabel.isEmpty
              ? context.l10n.t('all_classifieds')
              : widget.subcategoryLabel,
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ClassifiedsFilterScreen(subcategory: widget.subcategory),
              ),
            ),
            child: SizedBox(
              width: 44,
              height: kToolbarHeight,
              child: Center(
                child: Stack(clipBehavior: Clip.none, children: [
                  SvgPicture.asset('assets/icons/filter.svg',
                      width: 20, height: 20),
                  if (hasFilter)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: _kBlue, shape: BoxShape.circle),
                      ),
                    ),
                ]),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showSortSheet(context),
            child: SizedBox(
              width: 44,
              height: kToolbarHeight,
              child: Center(
                child: SvgPicture.asset('assets/icons/bars_sort.svg',
                    width: 20, height: 20),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: listingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(child: Text('${context.l10n.t('error')}: $e')),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    const Icon(Icons.grid_view_outlined,
                        size: 64, color: Colors.black26),
                    const SizedBox(height: 12),
                    Text(context.l10n.t('no_listings'),
                        style: GoogleFonts.poppins(
                            fontSize: 15, color: Colors.black45)),
                  ]))
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 245,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ClassifiedsDetailScreen(item: items[i]),
                  )),
                  child: _ClassifiedCard(item: items[i]),
                ),
              ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final filter = ref.read(classifiedsFilterProvider);
    final options = [
      ('Newest to Oldest', 'newest'),
      ('Oldest to Newest', 'oldest'),
      ('Price Highest to Lowest', 'price_high'),
      ('Price Lowest to Highest', 'price_low'),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(context.l10n.t('sort'),
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          ...options.map((opt) => ListTile(
                title: Text(_sortLabel(context, opt.$1), style: GoogleFonts.poppins(fontSize: 14)),
                trailing: filter.sortBy == opt.$2
                    ? const Icon(Icons.check, color: _kBlue)
                    : null,
                onTap: () {
                  ref.read(classifiedsFilterProvider.notifier).state =
                      filter.copyWith(sortBy: opt.$2);
                  context.pop();
                },
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ClassifiedCard extends StatefulWidget {
  final ClassifiedListingModel item;
  const _ClassifiedCard({required this.item});

  @override
  State<_ClassifiedCard> createState() => _ClassifiedCardState();
}

class _ClassifiedCardState extends State<_ClassifiedCard> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    if (widget.item.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % widget.item.images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
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

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7.38),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7.38),
                topRight: Radius.circular(7.38),
              ),
              child: item.images.isEmpty
                  ? _placeholder()
                  : SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: item.images.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (_, i) => Image(image: CachedNetworkImageProvider(sizedImageUrl(item.images[i])),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        ),
                      ),
                    ),
            ),
            if (item.images.isNotEmpty)
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.camera_alt_outlined,
                        size: 10, color: Colors.white),
                    const SizedBox(width: 3),
                    Text('${_currentPage + 1}/${item.images.length}',
                        style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                  ]),
                ),
              ),
            Positioned(
              top: 6,
              right: 6,
              child: Row(
                children: [
                  const _CircleBtn(icon: Icons.reply_outlined),
                  const SizedBox(width: 4),
                  FavoriteButton(
                    listingId: item.id,
                    size: 24,
                    backgroundColor: const Color(0x100F172A),
                        showShadow: false,
                    unselectedIconColor: Colors.white,
                    selectedIconColor: Colors.red,
                  ),
                ],
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(item.formattedPrice,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kBlue)),
                ),
                Text(_formatDate(item.createdAt),
                    style: GoogleFonts.poppins(
                        fontSize: 7.5, color: const Color(0xFF505050))),
              ]),
              TranslatedText(item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black)),
              Text(
                'Classifieds${item.brand.isNotEmpty ? ' / ${item.brand}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
              ),
              if (item.condition.isNotEmpty)
                Text('${context.l10n.t('Age')}: ${item.condition}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.black54)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 10, color: Color(0xFF505050)),
                const SizedBox(width: 2),
                Expanded(
                    child: TranslatedText(item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: const Color(0xFF505050)))),
              ]),
              const SizedBox(height: 4),
              const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
              const SizedBox(height: 4),
              Row(children: [
                const Spacer(),
                _contactBtn(Icons.phone_outlined, () => _call(item.phone)),
                const SizedBox(width: 6),
                _waBtn(() => _whatsapp(item.phone)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _contactBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 31,
        height: 22,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD9D9D9)),
          borderRadius: BorderRadius.circular(7),
          color: Colors.white,
        ),
        child: Center(child: Icon(icon, size: 14, color: _kBlue)),
      ),
    );
  }

  Widget _placeholder() => Container(
      height: 110,
      color: const Color(0xFFEDEDED),
      child: const Center(
          child: Icon(Icons.grid_view_outlined, color: Colors.grey, size: 36)));

  Widget _waBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 31,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          color: Colors.white,
        ),
        child: const Center(
            child: FaIcon(FontAwesomeIcons.whatsapp, size: 14, color: _kBlue)),
      ),
    );
  }

  void _call(String phone) => openPhoneCall(context, phone);

  void _whatsapp(String phone) => openWhatsApp(context, phone);
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  const _CircleBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration:
          const BoxDecoration(color: Color(0x100F172A), shape: BoxShape.circle),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }
}
