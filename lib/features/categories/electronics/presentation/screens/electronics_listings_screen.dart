import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/favorite_button.dart';
import '../../../../../core/widgets/translated_text.dart';
import '../../../../../features/listings/data/models/electronics_listing_model.dart';
import '../providers/electronics_provider.dart';
import 'electronics_detail_screen.dart';
import 'electronics_filter_screen.dart';
import '../../../../../core/utils/image_url.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/utils/phone_call.dart';
import '../../../../../core/utils/whatsapp.dart';

const _kBlue = Color(0xFF2258A8);

class ElectronicsListingsScreen extends ConsumerStatefulWidget {
  final String subcategory;
  final String subcategoryLabel;
  const ElectronicsListingsScreen({
    super.key,
    required this.subcategory,
    required this.subcategoryLabel,
  });

  @override
  ConsumerState<ElectronicsListingsScreen> createState() =>
      _ElectronicsListingsScreenState();
}

class _ElectronicsListingsScreenState
    extends ConsumerState<ElectronicsListingsScreen> {
  String _sortBy = 'newest';

  String _sortLabel(BuildContext context, String key) {
    switch (key) {
      case 'newest':
        return context.l10n.t('newest_to_oldest');
      case 'oldest':
        return context.l10n.t('oldest_to_newest');
      case 'price_high':
        return context.l10n.t('price_highest_to_lowest');
      case 'price_low':
        return context.l10n.t('price_lowest_to_highest');
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync =
        ref.watch(electronicsFilteredProvider(widget.subcategory));
    final filter = ref.watch(electronicsFilterProvider);

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
        title: TranslatedText(
          widget.subcategoryLabel,
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ElectronicsFilterScreen(subcategory: widget.subcategory),
                ),
              );
            },
            child: SizedBox(
              width: 44,
              height: kToolbarHeight,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset('assets/icons/filter.svg',
                        width: 20, height: 20),
                    if (!filter.isEmpty)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: _kBlue, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
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
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Text(context.l10n.t('no_listings'),
                  style: TextStyle(color: Colors.black45)),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 245,
            ),
            itemCount: listings.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ElectronicsDetailScreen(item: listings[i]),
                ),
              ),
              child: _ListingCard(item: listings[i]),
            ),
          );
        },
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final currentSort = ref.read(electronicsFilterProvider).sortBy;
        final options = [
          ('newest', 'Newest to Oldest'),
          ('oldest', 'Oldest to Newest'),
          ('price_high', 'Price Highest to Lowest'),
          ('price_low', 'Price Lowest to Highest'),
        ];
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(context.l10n.t('sort'),
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ...options.map(
              (opt) => ListTile(
                title: Text(_sortLabel(context, opt.$1), style: GoogleFonts.poppins(fontSize: 14)),
                trailing: currentSort == opt.$1 || _sortBy == opt.$1
                    ? const Icon(Icons.check, color: _kBlue)
                    : null,
                onTap: () {
                  setState(() => _sortBy = opt.$1);
                  ref.read(electronicsFilterProvider.notifier).update(
                        (f) => f.copyWith(sortBy: opt.$1),
                      );
                  context.pop();
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _ListingCard extends ConsumerWidget {
  final ElectronicsListingModel item;
  const _ListingCard({required this.item});

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
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7.38),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(7.38)),
                child: item.images.isEmpty
                    ? _placeholder()
                    : Image(image: CachedNetworkImageProvider(sizedImageUrl(item.imageUrl)),
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
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
              if (item.images.isNotEmpty)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x63000000),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image_outlined,
                            color: Colors.white, size: 9),
                        const SizedBox(width: 3),
                        Text(
                          '${item.images.length}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (item.isFeatured)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.l10n.t('featured'),
                      style: GoogleFonts.poppins(
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.formattedPrice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kBlue,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(item.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 7.5,
                        color: const Color(0xFF505050),
                      ),
                    ),
                  ],
                ),
                TranslatedText(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Electronics${item.brand.isNotEmpty ? ' / ${item.brand}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
                ),
                if (item.condition.isNotEmpty)
                  Text(
                    'Age: ${item.condition}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.black54),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 10, color: Color(0xFF505050)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF505050),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Spacer(),
                    _actionBtn(Icons.phone_outlined, () => _call(context, item.phone)),
                    const SizedBox(width: 6),
                    _waBtn(() => _whatsapp(context, item.phone)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback onTap) {
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
        child: Center(child: Icon(icon, size: 14, color: _kBlue)),
      ),
    );
  }

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

  Widget _placeholder() => Container(
        height: 110,
        color: const Color(0xFFEDEDED),
        child: const Center(
            child: Icon(Icons.devices_other, color: Colors.grey, size: 34)),
      );

  void _call(BuildContext context, String phone) => openPhoneCall(context, phone);

  void _whatsapp(BuildContext context, String phone) => openWhatsApp(context, phone);
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
