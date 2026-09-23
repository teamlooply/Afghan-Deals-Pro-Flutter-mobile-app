import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/widgets/favorite_button.dart';
import '../providers/spare_parts_provider.dart';
import 'spare_parts_detail_screen.dart';
import '../../../../../core/utils/image_url.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/utils/phone_call.dart';
import '../../../../../core/utils/whatsapp.dart';

const _kBlue = Color(0xFF2258A8);

class SparePartsResultsScreen extends ConsumerStatefulWidget {
  final String? initialMake;
  final String? initialModel;
  final int? fromYear;
  final int? toYear;
  const SparePartsResultsScreen({
    super.key,
    this.initialMake,
    this.initialModel,
    this.fromYear,
    this.toYear,
  });

  @override
  ConsumerState<SparePartsResultsScreen> createState() =>
      _SparePartsResultsScreenState();
}

class _SparePartsResultsScreenState
    extends ConsumerState<SparePartsResultsScreen> {
  String? _selectedRegion;
  String _sortBy = 'Newest to Oldest';

  static const _sortOptions = [
    'Newest to Oldest',
    'Oldest to Newest',
    'Price Highest to Lowest',
    'Price Lowest to Highest',
  ];

  List<SparePartListing> _sorted(List<SparePartListing> list) {
    final out = List<SparePartListing>.from(list);
    switch (_sortBy) {
      case 'Oldest to Newest':
        out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Price Highest to Lowest':
        out.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'Price Lowest to Highest':
        out.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      default:
        out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return out;
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                child: Text('Sort',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ),
            ),
            ..._sortOptions.map((item) {
              final selected = item == _sortBy;
              return InkWell(
                onTap: () {
                  setState(() => _sortBy = item);
                  context.pop();
                },
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(item,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87))),
                      if (selected)
                        const Icon(Icons.check, color: _kBlue, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openRegionSheet(List<String> regions) async {
    String? tempSelected = _selectedRegion;
    String search = '';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = regions
                .where((r) => r.toLowerCase().contains(search.toLowerCase()))
                .toList();

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCFCFCF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Select Region',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() => tempSelected = null);
                            },
                            child: Text(
                              'Clear',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _kBlue,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _RegionSearchBox(
                        onChanged: (v) {
                          setSheetState(() => search = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE8E9EB),
                          ),
                          itemBuilder: (_, index) {
                            final region = filtered[index];
                            final selected = tempSelected == region;
                            return InkWell(
                              onTap: () {
                                setSheetState(
                                  () => tempSelected = selected ? null : region,
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: selected,
                                      onChanged: (_) {
                                        setSheetState(
                                          () => tempSelected =
                                              selected ? null : region,
                                        );
                                      },
                                      side: const BorderSide(
                                          color: Color(0xFFBDBDBD)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      activeColor: _kBlue,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        region,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _selectedRegion = tempSelected);
                            context.pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Apply',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(
      sparePartListingsProvider(
        SparePartFilter(
          make: widget.initialMake,
          model: widget.initialModel,
          fromYear: widget.fromYear,
          toYear: widget.toYear,
          region: _selectedRegion,
        ),
      ),
    );
    final regionsAsync =
        ref.watch(sparePartRegionsProvider(widget.initialMake));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Results',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              final regions = regionsAsync.valueOrNull ?? <String>[];
              _openRegionSheet(regions);
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
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
        ),
      ),
      body: listingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
          ),
        ),
        data: (rawListings) {
          final listings = _sorted(rawListings);
          if (listings.isEmpty) {
            return Center(
              child: Text(
                'No listings',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 245,
            ),
            itemCount: listings.length,
            itemBuilder: (_, i) => _SparePartCard(listing: listings[i]),
          );
        },
      ),
    );
  }
}

class _RegionSearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _RegionSearchBox({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC2C2C2), width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 14, color: const Color(0xFF6B6B6B)),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _SparePartCard extends StatefulWidget {
  final SparePartListing listing;
  const _SparePartCard({required this.listing});

  @override
  State<_SparePartCard> createState() => _SparePartCardState();
}

class _SparePartCardState extends State<_SparePartCard> {
  PageController? _controller;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final count = widget.listing.images.length;
    if (count > 1) {
      _controller = PageController(viewportFraction: 1);
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || _controller == null) return;
        final next = (_currentPage + 1) % count;
        _controller!.animateToPage(
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
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.listing;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SparePartsDetailScreen(listing: item),
          ),
        );
      },
      child: Container(
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
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7.38),
                    topRight: Radius.circular(7.38),
                  ),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: item.images.isEmpty
                        ? _placeholderImage()
                        : _controller == null
                            ? Image(image: CachedNetworkImageProvider(sizedImageUrl(item.images.first)),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderImage(),
                              )
                            : PageView.builder(
                                controller: _controller,
                                itemCount: item.images.length,
                                onPageChanged: (i) =>
                                    setState(() => _currentPage = i),
                                itemBuilder: (_, i) => Image(image: CachedNetworkImageProvider(sizedImageUrl(item.images[i])),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholderImage(),
                                ),
                              ),
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
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                            height: 1.3,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(item.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 7.5,
                          color: const Color(0xFF505050),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 1.3),
                  ),
                  if (item.subtitle.isNotEmpty)
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.black54, height: 1.3),
                    ),
                  if (item.yearMileageLine.isNotEmpty)
                    Text(
                      item.yearMileageLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.black54, height: 1.3),
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
                              height: 1.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionBtn(
                        child: const Icon(Icons.phone_outlined,
                            color: _kBlue, size: 14),
                        onTap: () => _launchCall(item.phone),
                      ),
                      const SizedBox(width: 6),
                      _ActionBtn(
                        child: const FaIcon(FontAwesomeIcons.whatsapp,
                            color: _kBlue, size: 13),
                        onTap: () => _launchWhatsApp(item.phone),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: const Center(
        child: Icon(Icons.build_outlined, size: 40, color: Colors.grey),
      ),
    );
  }

  String _formatDate(DateTime dt) {
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
      'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    return '$day ${months[dt.month - 1]}, ${dt.year}';
  }

  Future<void> _launchCall(String phone) => openPhoneCall(context, phone);

  Future<void> _launchWhatsApp(String phone) => openWhatsApp(context, phone);
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
