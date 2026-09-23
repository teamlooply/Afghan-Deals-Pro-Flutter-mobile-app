import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/localized_lookup.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/favorite_button.dart';
import '../../../../../core/widgets/translated_text.dart';
import 'property_detail_screen.dart';
import 'property_filter_screen.dart';
import '../../data/models/property_listing_model.dart';
import '../providers/property_filtered_listings_provider.dart';
import '../../../../../core/utils/image_url.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/utils/phone_call.dart';
import '../../../../../core/utils/whatsapp.dart';

// ignore_for_file: unused_import

const _kBlue = Color(0xFF2258A8);

class PropertyFilterOptions {
  final List<String> subcategories;
  final List<String> propertyTypes;
  final List<String> bedrooms;
  final List<String> bathrooms;
  final List<String> furnishings;
  final List<String> cities;
  final double maxPrice;

  const PropertyFilterOptions({
    required this.subcategories,
    required this.propertyTypes,
    required this.bedrooms,
    required this.bathrooms,
    required this.furnishings,
    required this.cities,
    required this.maxPrice,
  });
}

class PropertyListingsScreen extends ConsumerStatefulWidget {
  final String subcategoryName;
  final String subcategorySlug;
  final String? initialPropertyType;

  const PropertyListingsScreen({
    super.key,
    required this.subcategoryName,
    required this.subcategorySlug,
    this.initialPropertyType,
  });

  @override
  ConsumerState<PropertyListingsScreen> createState() =>
      _PropertyListingsScreenState();
}

class _PropertyListingsScreenState
    extends ConsumerState<PropertyListingsScreen> {
  late String? _activeType;
  String _selectedSort = 'Popular';
  AppliedPropertyFilters? _appliedFilters;

  static const _sortOptions = [
    'Popular',
    'Newest to Oldest',
    'Oldest to Newest',
    'Price Highest to Lowest',
    'Price Lowest to Highest',
  ];

  String _sortLabel(BuildContext context, String value) =>
      localizedCarSortLabel(context.l10n, value);

  List<PropertyListingModel> _applyFilters(
      List<PropertyListingModel> listings) {
    final filters = _appliedFilters;
    if (filters == null || filters.isEmpty) return listings;

    return listings.where((item) {
      final price = double.tryParse(item.price) ?? 0;
      if (price < filters.minPrice || price > filters.maxPrice) return false;
      if (filters.subcategories.isNotEmpty &&
          !filters.subcategories.any((s) =>
              item.subcategory.toLowerCase().contains(s.toLowerCase()) ||
              item.title.toLowerCase().contains(s.toLowerCase()))) {
        return false;
      }
      if (filters.propertyTypes.isNotEmpty &&
          !filters.propertyTypes.any((s) =>
              item.propertyType.toLowerCase().contains(s.toLowerCase()))) {
        return false;
      }
      if (filters.bedrooms.isNotEmpty &&
          !filters.bedrooms.contains(item.bedrooms.toString())) {
        return false;
      }
      if (filters.bathrooms.isNotEmpty &&
          !filters.bathrooms.contains(item.bathrooms.toString())) {
        return false;
      }
      if (filters.furnishings.isNotEmpty &&
          !filters.furnishings.any(
              (s) => item.furnishing.toLowerCase().contains(s.toLowerCase()))) {
        return false;
      }
      if (filters.locations.isNotEmpty &&
          !filters.locations.any(
              (s) => item.location.toLowerCase().contains(s.toLowerCase()))) {
        return false;
      }
      return true;
    }).toList();
  }

  PropertyFilterOptions _buildFilterOptions(
      List<PropertyListingModel> listings) {
    List<String> distinct(Iterable<String> values) {
      final clean = values
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return clean;
    }

    final maxPrice = listings
        .map((e) => double.tryParse(e.price) ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return PropertyFilterOptions(
      subcategories: distinct(listings.map((e) => e.subcategory)),
      propertyTypes: distinct(listings.map((e) => e.propertyType)),
      bedrooms: distinct(
          listings.map((e) => e.bedrooms == 0 ? '' : e.bedrooms.toString())),
      bathrooms: distinct(
          listings.map((e) => e.bathrooms == 0 ? '' : e.bathrooms.toString())),
      furnishings: distinct(listings.map((e) => e.furnishing)),
      cities: distinct(listings.map((e) => e.location)),
      maxPrice: ((maxPrice <= 0 ? 150000 : maxPrice) / 5000).ceil() * 5000,
    );
  }

  @override
  void initState() {
    super.initState();
    _activeType = widget.initialPropertyType;
  }

  Widget _buildSellFab() {
    return SizedBox(
      width: 58,
      height: 58,
      child: CustomPaint(
        foregroundPainter: _SellRingPainter(),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Color(0x25000000), blurRadius: 8, offset: Offset(0, 2))
            ],
          ),
          child: const Center(child: Icon(Icons.add, color: _kBlue, size: 28)),
        ),
      ),
    );
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCFCFCF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(context.l10n.t('sort'),
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
              ),
              child: Column(
                children: _sortOptions.map((item) {
                  final selected = item == _selectedSort;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedSort = item);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(color: Color(0xFFE8E9EB), width: 1)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                        child: Text(_sortLabel(context, item),
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87)),
                          ),
                          if (selected)
                            const Icon(Icons.check, color: _kBlue, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<PropertyListingModel> _sorted(List<PropertyListingModel> list) {
    final copy = List<PropertyListingModel>.from(list);
    switch (_selectedSort) {
      case 'Newest to Oldest':
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest to Newest':
        copy.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Price Highest to Lowest':
        copy.sort((a, b) => (double.tryParse(b.price) ?? 0)
            .compareTo(double.tryParse(a.price) ?? 0));
        break;
      case 'Price Lowest to Highest':
        copy.sort((a, b) => (double.tryParse(a.price) ?? 0)
            .compareTo(double.tryParse(b.price) ?? 0));
        break;
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final filter = PropertyFilter(subcategorySlug: widget.subcategorySlug);
    final listingsAsync = ref.watch(propertyFilteredListingsProvider(filter));
    final cities = ref.watch(propertyLocationsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildSellFab(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: Colors.black87),
        ),
        title: Text(
          widget.subcategoryName,
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              final loadedListings = listingsAsync.valueOrNull ?? [];
              final currentListings = _activeType == null
                  ? loadedListings
                  : loadedListings
                      .where((l) =>
                          l.propertyType.toLowerCase() ==
                          _activeType!.toLowerCase())
                      .toList();
              final options = _buildFilterOptions(currentListings);
              final result =
                  await Navigator.of(context).push<AppliedPropertyFilters>(
                MaterialPageRoute(
                  builder: (_) => PropertyFilterScreen(
                    cities: options.cities.isEmpty ? cities : options.cities,
                    subcategories: options.subcategories,
                    propertyTypes: options.propertyTypes,
                    bedrooms: options.bedrooms,
                    bathrooms: options.bathrooms,
                    furnishings: options.furnishings,
                    maxPrice: options.maxPrice,
                    initialFilters: _appliedFilters,
                  ),
                ),
              );
              if (result != null) {
                setState(() => _appliedFilters = result);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SvgPicture.asset('assets/icons/filter.svg',
                  width: 20, height: 20),
            ),
          ),
          GestureDetector(
            onTap: _openSortSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SvgPicture.asset('assets/icons/bars_sort.svg',
                  width: 20, height: 20),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: listingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(
            child: Text('${context.l10n.t('error')}: $e',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.red))),
        data: (allListings) {
          // Client-side type filter
          final filtered = _activeType == null
              ? allListings
              : allListings
                  .where((l) =>
                      l.propertyType.toLowerCase() ==
                      _activeType!.toLowerCase())
                  .toList();

          final listings = _sorted(_applyFilters(filtered));

          return Column(
            children: [
              // ── Listings ─────────────────────────────────────────────
              Expanded(
                child: listings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.home_work_outlined,
                                size: 64, color: Color(0xFFCCCCCC)),
                            const SizedBox(height: 12),
                            Text(context.l10n.t('no_listings'),
                                style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54)),
                            if (_activeType != null) ...[
                              const SizedBox(height: 4),
                              Text(_activeType!,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.black38)),
                            ],
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 245,
                        ),
                        itemCount: listings.length,
                        itemBuilder: (_, i) => _PropertyCard(item: listings[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Property Card ─────────────────────────────────────────────────────────────
class _PropertyCard extends StatefulWidget {
  final PropertyListingModel item;
  const _PropertyCard({required this.item});

  @override
  State<_PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<_PropertyCard> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    if (widget.item.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % widget.item.images.length;
        _pageController.animateToPage(next,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic);
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
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final createdDate = _formatDate(item.createdAt);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PropertyDetailScreen(property: item),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7.38),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
          boxShadow: const [
            BoxShadow(
                color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7.38),
                    topRight: Radius.circular(7.38),
                  ),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: item.images.isEmpty
                        ? _placeholder()
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: item.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemBuilder: (_, i) => Image(image: CachedNetworkImageProvider(sizedImageUrl(item.images[i])),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            ),
                          ),
                  ),
                ),
                // Share + Heart
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
                // Photo count
                if (item.images.isNotEmpty)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
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
                            item.images.length > 1
                                ? '${_currentPage + 1}/${item.images.length}'
                                : '${item.images.length}',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                height: 1),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(context.l10n.t('featured'),
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),

            // ── Content ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price + date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(item.formattedPrice,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kBlue)),
                      ),
                      Text(createdDate,
                          style: GoogleFonts.poppins(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF505050))),
                    ],
                  ),
                  // Title
                  TranslatedText(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.black)),
                  // Details — 2 per row with icons
                  ..._buildDetailRows(item),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 10, color: Color(0xFF505050)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: TranslatedText(item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF505050))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                  const SizedBox(height: 4),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionBtn(
                        child: const Icon(Icons.phone_outlined,
                            color: _kBlue, size: 14),
                        onTap: () => openPhoneCall(context, widget.item.phone),
                      ),
                      const SizedBox(width: 6),
                      _ActionBtn(
                        child: const FaIcon(FontAwesomeIcons.whatsapp,
                            color: _kBlue, size: 14),
                        onTap: () => openWhatsApp(context, widget.item.phone),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ), // Container
    ); // GestureDetector
  }

  List<Widget> _buildDetailRows(PropertyListingModel item) {
    // Build list of (icon, label) pairs for available fields
    final details = <(IconData, String)>[];
    if (item.bedrooms > 0) {
      details.add((Icons.bed_outlined, '${item.bedrooms} Beds'));
    }
    if (item.bathrooms > 0) {
      details.add((Icons.bathtub_outlined, '${item.bathrooms} Baths'));
    }
    if (item.area.isNotEmpty) {
      details.add((Icons.square_foot, item.area));
    }
    if (item.propertyType.isNotEmpty) {
      details.add((Icons.home_work_outlined, item.propertyType));
    }

    if (details.isEmpty) return [];

    // Group into rows of 2
    final rows = <Widget>[];
    for (int i = 0; i < details.length; i += 2) {
      final left = details[i];
      final right = i + 1 < details.length ? details[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: [
              Expanded(child: _detailItem(left.$1, left.$2)),
              if (right != null)
                Expanded(child: _detailItem(right.$1, right.$2)),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  Widget _detailItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 10, color: const Color(0xFF505050)),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 9.5,
                fontWeight: FontWeight.w400,
                color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
      height: 110,
      color: const Color(0xFFEDEDED),
      child: const Center(
          child: Icon(Icons.home_work_outlined, color: Colors.grey, size: 34)));
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  const _CircleBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0x100F172A),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ActionBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 31,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
          color: Colors.white,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _SellRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeW = 6.5;
    final radius = size.width / 2 - strokeW / 2 - 1;
    final rect = Rect.fromCircle(center: center, radius: radius);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;
    const third = 2 * pi / 3;
    canvas.drawArc(rect, -pi / 2, third, false, arc(const Color(0xFF1D57A7)));
    canvas.drawArc(
        rect, -pi / 2 + third, third, false, arc(const Color(0xFF000000)));
    canvas.drawArc(
        rect, -pi / 2 + 2 * third, third, false, arc(const Color(0xFF3B77FE)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
