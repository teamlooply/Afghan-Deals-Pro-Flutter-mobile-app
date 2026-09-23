import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/jobs_provider.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/localized_lookup.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/favorite_button.dart';
import '../../../../../core/widgets/translated_text.dart';
import '../../../../../features/chat/presentation/providers/chat_provider.dart';
import '../../../../../features/listings/data/models/jobs_listing_model.dart';
import 'jobs_detail_screen.dart';
import 'jobs_filter_screen.dart';
import '../../../../../core/utils/image_url.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/utils/phone_call.dart';
import '../../../../../core/utils/whatsapp.dart';

const _kBlue = Color(0xFF2258A8);

class JobsListingsScreen extends ConsumerStatefulWidget {
  final String subcategory;
  final String subcategoryLabel;
  const JobsListingsScreen({
    super.key,
    required this.subcategory,
    required this.subcategoryLabel,
  });

  @override
  ConsumerState<JobsListingsScreen> createState() => _JobsListingsScreenState();
}

class _JobsListingsScreenState extends ConsumerState<JobsListingsScreen> {
  String _sortLabel(BuildContext context, String value) {
    switch (value) {
      case 'Salary Highest to Lowest':
        return context.l10n.t('max_salary');
      case 'Salary Lowest to Highest':
        return context.l10n.t('min_salary');
      default:
        return localizedCarSortLabel(context.l10n, value);
    }
  }

  Future<void> _handleChat(
      WidgetRef ref, BuildContext context, JobsListingModel item) async {
    try {
      final chatId =
          await ref.read(chatActionsProvider).openOrCreateChatForListing(
                listingId: item.id,
                sellerId: item.sellerId,
              );
      if (!context.mounted) return;
      context.push('/chat/$chatId');
    } catch (e) {
      if (!context.mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      if (message.toLowerCase().contains('please sign in first')) {
        Navigator.of(context).pushNamed(RouteNames.onboarding);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(jobsFilteredProvider(widget.subcategory));
    final filter = ref.watch(jobsFilterProvider);
    final hasFilter = !filter.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.subcategoryLabel.isEmpty
              ? context.l10n.t('jobs')
              : widget.subcategoryLabel,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 28 / 15,
            color: Colors.black87,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => JobsFilterScreen(subcategory: widget.subcategory),
            )),
            child: SizedBox(
              width: 44,
              height: kToolbarHeight,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
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
                            color: _kBlue,
                            shape: BoxShape.circle,
                          ),
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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
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
                      const Icon(Icons.work_outline,
                          size: 64, color: Colors.black26),
                      const SizedBox(height: 12),
                      Text(context.l10n.t('no_jobs_found'),
                          style: GoogleFonts.poppins(
                              fontSize: 15, color: Colors.black45)),
                    ]),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 245,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _JobResultCard(
                  item: items[i],
                  onCardTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => JobsDetailScreen(item: items[i]),
                  )),
                  onChat: () => _handleChat(ref, context, items[i]),
                ),
              ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final filter = ref.read(jobsFilterProvider);
    final options = [
      ('Newest to Oldest', 'newest'),
      ('Oldest to Newest', 'oldest'),
      ('Salary Highest to Lowest', 'salary_high'),
      ('Salary Lowest to Highest', 'salary_low'),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                  ref.read(jobsFilterProvider.notifier).state =
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

class _JobResultCard extends StatefulWidget {
  final JobsListingModel item;
  final VoidCallback onCardTap;
  final VoidCallback onChat;
  const _JobResultCard(
      {required this.item, required this.onCardTap, required this.onChat});

  @override
  State<_JobResultCard> createState() => _JobResultCardState();
}

class _JobResultCardState extends State<_JobResultCard> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
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

  void _handleShare() {
    final text =
        '${widget.item.title}\n${widget.item.formattedPrice}\n${widget.item.location}';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share'),
        content: Text('Shared: $text'),
        actions: [
          IconButton(
              icon: const Icon(Icons.close), onPressed: () => context.pop())
        ],
      ),
    );
  }

  Future<void> _handleCall() => openPhoneCall(context, widget.item.phone);

  void _handleChat() {
    widget.onChat();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTap: widget.onCardTap,
      child: Container(
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(7.38)),
                child: item.images.isEmpty
                    ? _placeholder()
                    : SizedBox(
                        height: 110,
                        width: double.infinity,
                        child: PageView.builder(
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
              if (item.images.isNotEmpty)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0x63000000),
                        borderRadius: BorderRadius.circular(4)),
                    child: Row(children: [
                      const Icon(Icons.image_outlined,
                          color: Colors.white, size: 9),
                      const SizedBox(width: 3),
                      Text('${_currentPage + 1}/${item.images.length}',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              height: 1)),
                    ]),
                  ),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _handleShare,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                            color: Color(0x100F172A), shape: BoxShape.circle),
                        child: const Icon(Icons.reply_outlined,
                            size: 13, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 4),
                    FavoriteButton(
                      listingId: widget.item.id,
                      size: 28,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    ],
                  ),
                  TranslatedText(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.black)),
                  Text('Jobs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.black54)),
                  if (item.experience.isNotEmpty)
                    Text('Experience: ${item.experience}',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.black54)),
                  const SizedBox(height: 4),
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
                                fontSize: 10, color: const Color(0xFF505050))),
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
                      GestureDetector(
                        onTap: _handleCall,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 31,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: const Color(0xFFD9D9D9), width: 1),
                            color: Colors.white,
                          ),
                          child: const Center(
                              child: Icon(Icons.phone_outlined,
                                  size: 14, color: _kBlue)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _handleChat,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 31,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: const Color(0xFFD9D9D9), width: 1),
                            color: Colors.white,
                          ),
                          child: const Center(
                              child: Icon(Icons.chat_bubble_outline,
                                  size: 14, color: _kBlue)),
                        ),
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

  Widget _placeholder() => Container(
      height: 110,
      width: double.infinity,
      color: const Color(0xFFEDEDED),
      alignment: Alignment.center,
      child: const Icon(Icons.work_outline, color: Colors.grey, size: 34));
}
