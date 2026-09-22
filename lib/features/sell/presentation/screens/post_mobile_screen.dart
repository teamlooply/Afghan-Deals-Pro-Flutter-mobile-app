import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../providers/sell_provider.dart';
import '../providers/sell_subcategories_provider.dart';
import '../../../../core/auth/app_auth.dart';

// ── Static options ─────────────────────────────────────────────────────────────

const _kBrands = [
  'iPhone',
  'Samsung',
  'Vivo',
  'Oppo',
  'OnePlus',
  'Google Pixel',
  'Realme',
  'Xiaomi',
  'Huawei',
  'Sony',
  'Nokia',
  'Motorola',
  'LG',
  'HTC',
  'Other',
];

const _kConditions = ['New', 'Used', 'Refurbished', 'For Parts'];

const _kStorages = [
  '16 GB',
  '32 GB',
  '64 GB',
  '128 GB',
  '256 GB',
  '512 GB',
  '1 TB'
];

const _kRams = ['2 GB', '3 GB', '4 GB', '6 GB', '8 GB', '12 GB', '16 GB'];

const _kScreenSizes = [
  'Under 5"',
  '5" - 5.5"',
  '5.5" - 6"',
  '6" - 6.5"',
  'Above 6.5"',
];

const _kWarranties = [
  'No Warranty',
  'Under Warranty',
  '1 Month',
  '3 Months',
  '6 Months',
  '1 Year',
];

const _kCurrencies = [
  'AFN',
  'USD',
  'AED',
  'OMR',
  'QAR',
  'SAR',
  'SYP',
  'EUR',
  'GBP',
  'PKR'
];

const _kSellerTypes = ['Individual', 'Dealer', 'Brand'];

const _kColors = [
  'Black',
  'White',
  'Gold',
  'Silver',
  'Blue',
  'Red',
  'Green',
  'Purple',
  'Pink',
  'Yellow',
  'Orange',
  'Grey',
  'Other',
];

const _kAges = [
  'Brand New',
  '1 Month',
  '3 Months',
  '6 Months',
  '1 Year',
  '2+ Years'
];
const _kBatteryHealth = ['100%', '95%+', '90%+', '85%+', '80%+', 'Below 80%'];

String _slugForMobileBrand(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

class _Country {
  final String name;
  final String flag;
  const _Country(this.name, this.flag);
}

const _kCountries = [
  _Country('Afghanistan', 'assets/images/flags/afghanistan.png'),
  _Country('UAE', 'assets/images/flags/uae.png'),
  _Country('Qatar', 'assets/images/flags/qatar.png'),
  _Country('Oman', 'assets/images/flags/oman.png'),
  _Country('KSA', 'assets/images/flags/ksa.png'),
  _Country('Syria', 'assets/images/flags/syria.png'),
];

const _kBlue = Color(0xFF2258A8);

// ── Screen ─────────────────────────────────────────────────────────────────────

class PostMobileScreen extends ConsumerStatefulWidget {
  const PostMobileScreen({super.key});

  @override
  ConsumerState<PostMobileScreen> createState() => _PostMobileScreenState();
}

class _PostMobileScreenState extends ConsumerState<PostMobileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _damageCtrl = TextEditingController();
  final _screenSizeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _versionCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  // Selections
  String _brand = '';
  String _condition = '';
  String _storage = '';
  String _ram = '';
  String _screenSize = '';
  String _color = '';
  String _warranty = '';
  String _sellerType = 'Individual';
  String _currency = 'AFN';
  _Country _country = _kCountries.first;
  String _age = '';
  String _battery = '';
  String _selectedSubcategory = '';

  @override
  void initState() {
    super.initState();
    // Phone-login users already gave us their number; everyone else types it.
    _whatsappCtrl.text = AppAuth.currentUserPhone?.trim() ?? '';
  }

  @override
  void dispose() {
    _whatsappCtrl.dispose();
    _titleCtrl.dispose();
    _modelCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _damageCtrl.dispose();
    _screenSizeCtrl.dispose();
    _cityCtrl.dispose();
    _versionCtrl.dispose();
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_condition.isEmpty) {
      _showError('Please select condition');
      return;
    }
    if (_cityCtrl.text.trim().isEmpty) {
      _showError('Please enter your city');
      return;
    }

    final brand = _brand.trim();
    final brandSlug = _slugForMobileBrand(brand);
    final selectedSubcategory = _selectedSubcategory.isNotEmpty
        ? _selectedSubcategory
        : (brandSlug.isNotEmpty ? brandSlug : 'mobile-phones');

    await ref.read(sellProvider.notifier).createListing(
      category: 'mobiles',
      baseData: {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'currency': _currency,
        'city': _cityCtrl.text.trim(),
        'country': _country.name,
        'subcategory': selectedSubcategory,
      },
      categoryData: {
        'subcategory': selectedSubcategory,
        'brand': brand,
        'brand_slug': brandSlug,
        'model': _modelCtrl.text.trim(),
        'condition': _condition,
        'storage': _storage,
        'ram': _ram,
        'age': _age,
        'screen_size': _screenSize,
        'color': _color,
        if (_whatsappCtrl.text.trim().isNotEmpty) ...{
          'whatsapp': _whatsappCtrl.text.trim(),
          'phone': _whatsappCtrl.text.trim(),
          'seller_phone': _whatsappCtrl.text.trim(),
        },
        'warranty': _warranty,
        'battery_health': _battery,
        'version': _versionCtrl.text.trim(),
        'damage_details': _damageCtrl.text.trim(),
        'seller_type': _sellerType,
        'country': _country.name,
        'city': _cityCtrl.text.trim(),
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _showCurrencyPicker() {
    _showPicker('Currency', _kCurrencies, (v) => setState(() => _currency = v));
  }

  Widget _buildSubcategorySection(
      AsyncValue<List<SellSubcategory>> asyncSubcategories) {
    return asyncSubcategories.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, __) => Text(
        'Unable to load subcategories. You can still post.',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
      ),
      data: (subcategories) {
        if (_selectedSubcategory.isEmpty && subcategories.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedSubcategory.isEmpty) {
              setState(() {
                _selectedSubcategory = subcategories.first.slug;
                if (_brand.isEmpty) {
                  _brand = subcategories.first.name;
                }
              });
            }
          });
        }

        if (subcategories.isEmpty) {
          return Text(
            'No subcategory configured in dashboard for mobiles.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          );
        }

        return Column(
          children: subcategories.map((sub) {
            final selected = _selectedSubcategory == sub.slug;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedSubcategory = sub.slug;
                  _brand = sub.name;
                }),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected ? _kBlue : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? _kBlue : const Color(0xFFDDDDDD),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          sub.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sell = ref.watch(sellProvider);
    final subcategoriesAsync = ref.watch(sellSubcategoriesProvider('mobiles'));

    // Listen for success / error
    ref.listen(sellProvider, (_, next) {
      if (next.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Ad submitted. It will be visible after admin approval.',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
        ref.read(sellProvider.notifier).reset();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
      if (next.error != null) {
        _showError(next.error!);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.l10n.t('Post Mobile Ad'),
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photos section ───────────────────────────────────────────
              _PhotoSection(sell: sell),
              const SizedBox(height: 8),

              _Section(
                title: 'Ad Type',
                children: [
                  _Field(
                    label: 'Subcategory',
                    child: _buildSubcategorySection(subcategoriesAsync),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Ad Details ───────────────────────────────────────────────
              _Section(
                title: 'Ad Details',
                children: [
                  _Field(
                    label: 'Title *',
                    child: _textInput(
                      controller: _titleCtrl,
                      hint: 'e.g. iPhone 15 Pro Max 256GB',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Title is required'
                          : null,
                    ),
                  ),
                  _Field(
                    label: 'Description *',
                    child: _textInput(
                      controller: _descCtrl,
                      hint:
                          'Describe the condition, accessories included, reason for selling...',
                      maxLines: 4,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Description is required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Mobile Info ──────────────────────────────────────────────
              _Section(
                title: 'Mobile Details',
                children: [
                  _Field(
                    label: 'Brand',
                    child: _DropdownTile(
                      value: _brand.isEmpty ? 'Select brand' : _brand,
                      onTap: () => _showPicker(
                        'Brand',
                        _kBrands,
                        (v) => setState(() {
                          _brand = v;
                          _selectedSubcategory = _slugForMobileBrand(v);
                        }),
                      ),
                    ),
                  ),
                  _Field(
                    label: 'Model',
                    child: _textInput(
                      controller: _modelCtrl,
                      hint: 'e.g. iPhone 15 Pro Max',
                    ),
                  ),
                  _Field(
                    label: 'Condition *',
                    child: _ChipGroup(
                      options: _kConditions,
                      selected: _condition,
                      onSelect: (v) => setState(() => _condition = v),
                    ),
                  ),
                  _Field(
                    label: 'Storage',
                    child: _DropdownTile(
                      value: _storage.isEmpty ? 'Select storage' : _storage,
                      onTap: () => _showPicker('Storage', _kStorages,
                          (v) => setState(() => _storage = v)),
                    ),
                  ),
                  _Field(
                    label: 'RAM',
                    child: _DropdownTile(
                      value: _ram.isEmpty ? 'Select RAM' : _ram,
                      onTap: () => _showPicker(
                          'RAM', _kRams, (v) => setState(() => _ram = v)),
                    ),
                  ),
                  _Field(
                    label: 'Age',
                    child: _DropdownTile(
                      value: _age.isEmpty ? 'Select age' : _age,
                      onTap: () => _showPicker(
                          'Age', _kAges, (v) => setState(() => _age = v)),
                    ),
                  ),
                  _Field(
                    label: 'Screen Size',
                    child: _DropdownTile(
                      value: _screenSize.isEmpty
                          ? 'Select screen size'
                          : _screenSize,
                      onTap: () => _showPicker('Screen Size', _kScreenSizes,
                          (v) => setState(() => _screenSize = v)),
                    ),
                  ),
                  _Field(
                    label: 'Color',
                    child: _DropdownTile(
                      value: _color.isEmpty ? 'Select color' : _color,
                      onTap: () => _showPicker(
                          'Color', _kColors, (v) => setState(() => _color = v)),
                    ),
                  ),
                  _Field(
                    label: 'Warranty',
                    child: _DropdownTile(
                      value: _warranty.isEmpty ? 'Select warranty' : _warranty,
                      onTap: () => _showPicker('Warranty', _kWarranties,
                          (v) => setState(() => _warranty = v)),
                    ),
                  ),
                  _Field(
                    label: 'Battery Health',
                    child: _DropdownTile(
                      value:
                          _battery.isEmpty ? 'Select battery health' : _battery,
                      onTap: () => _showPicker(
                        'Battery Health',
                        _kBatteryHealth,
                        (v) => setState(() => _battery = v),
                      ),
                    ),
                  ),
                  _Field(
                    label: 'Version',
                    child: _textInput(
                      controller: _versionCtrl,
                      hint: 'e.g. International, PTA Approved',
                    ),
                  ),
                  _Field(
                    label: 'Damage / Defects',
                    child: _textInput(
                      controller: _damageCtrl,
                      hint: 'Describe any damage or leave blank if none',
                      maxLines: 2,
                    ),
                  ),
                  _Field(
                    label: 'Seller Type',
                    child: _ChipGroup(
                      options: _kSellerTypes,
                      selected: _sellerType,
                      onSelect: (v) => setState(() => _sellerType = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Price ────────────────────────────────────────────────────
              _Section(
                title: 'Price',
                children: [
                  _Field(
                    label: 'Price *',
                    child: Row(
                      children: [
                        // Currency picker
                        GestureDetector(
                          onTap: _showCurrencyPicker,
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: _kBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(_currency,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down,
                                    size: 16, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _textInput(
                            controller: _priceCtrl,
                            hint: '0',
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Price is required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Location ─────────────────────────────────────────────────
              _Section(
                title: 'Location',
                children: [
                  _Field(
                    label: 'Country',
                    child: GestureDetector(
                      onTap: () => _showPicker(
                        'Country',
                        _kCountries.map((c) => c.name).toList(),
                        (v) => setState(() {
                          _country = _kCountries.firstWhere((c) => c.name == v);
                        }),
                      ),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDDDDDD)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Image.asset(
                                _country.flag,
                                width: 28,
                                height: 19,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.flag, size: 20),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _country.name,
                                style: GoogleFonts.poppins(
                                    fontSize: 14, color: Colors.black87),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down,
                                size: 20, color: Colors.black45),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _Field(
                    label: 'City *',
                    child: _textInput(
                      controller: _cityCtrl,
                      hint: 'e.g. Kabul, Dubai',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'City is required'
                          : null,
                    ),
                  ),
                  _Field(
                    label: 'WhatsApp Number',
                    child: _textInput(
                      controller: _whatsappCtrl,
                      hint: 'e.g. +93 70 123 4567',
                      keyboardType: TextInputType.phone,
                      validator: _validateWhatsapp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // ── Bottom submit button ─────────────────────────────────────────────────
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: sell.isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              disabledBackgroundColor: _kBlue.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: sell.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(context.l10n.t('Post Ad'),
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
          ),
        ),
      ),
    );
  }

  // ── Picker bottom sheet ─────────────────────────────────────────────────────

  void _showPicker(
      String title, List<String> options, ValueChanged<String> onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text(context.l10n.t(title),
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const Divider(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) => InkWell(
                onTap: () {
                  onSelect(options[i]);
                  Navigator.pop(context);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Text(context.l10n.t(options[i]),
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.black87)),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String? _validateWhatsapp(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null; // optional
    if (digits.length < 9 || digits.length > 15) {
      return 'Enter the number with country code, e.g. +93 70 123 4567';
    }
    return null;
  }

  Widget _textInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: context.l10n.t(hint),
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

// ── Photo section ──────────────────────────────────────────────────────────────

class _PhotoSection extends ConsumerWidget {
  final SellState sell;
  const _PhotoSection({required this.sell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(sellProvider.notifier);
    final images = sell.images;
    final remaining = 10 - images.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.l10n.t('Photos'),
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('${images.length}/10',
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
              const Spacer(),
              if (remaining > 0)
                Text('$remaining ${context.l10n.t('more')}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.black38)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Add button (only if < 10 images)
                if (images.length < 10)
                  GestureDetector(
                    onTap: () => _showImageSourceSheet(context, notifier),
                    child: Container(
                      width: 96,
                      height: 96,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _kBlue.withValues(alpha: 0.4),
                            width: 1.5,
                            strokeAlign: BorderSide.strokeAlignInside),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              color: _kBlue, size: 28),
                          const SizedBox(height: 4),
                          Text(context.l10n.t('Add Photo'),
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _kBlue)),
                        ],
                      ),
                    ),
                  ),

                // Image thumbnails
                ...images.asMap().entries.map((e) {
                  final idx = e.key;
                  final img = e.value;
                  return Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: FileImage(File(img.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Cover badge for first image
                      if (idx == 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            decoration: const BoxDecoration(
                              color: Color(0xCC000000),
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(10)),
                            ),
                            child: Text(context.l10n.t('Cover'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      // Remove button
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => notifier.removeImage(idx),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'First photo will be the cover. Tap + to add up to 10 photos.',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context, SellNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.photo_library_outlined, color: _kBlue),
                title: Text(context.l10n.t('Choose from Gallery'),
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  notifier.pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: _kBlue),
                title: Text(context.l10n.t('Take a Photo'),
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  notifier.pickFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section wrapper ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.t(title),
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ── Field row ─────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.t(label),
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// ── Dropdown tile ─────────────────────────────────────────────────────────────

class _DropdownTile extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const _DropdownTile({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value.startsWith('Select');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.t(value),
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isPlaceholder ? Colors.black38 : Colors.black87),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 20, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

// ── Chip group (for condition, seller type) ───────────────────────────────────

class _ChipGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? _kBlue : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? _kBlue : const Color(0xFFDDDDDD),
              ),
            ),
            child: Text(
              context.l10n.t(opt),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
