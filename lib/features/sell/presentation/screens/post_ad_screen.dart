import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/sell_provider.dart';
import '../providers/sell_subcategories_provider.dart';
import '../widgets/customer_posting_section.dart';
import '../providers/staff_provider.dart';

class _Country {
  final String name;
  final String code;
  final String flag;
  final String currency;
  const _Country(this.name, this.code, this.flag, this.currency);
}

const _kCountries = [
  _Country('Afghanistan', 'AF', 'assets/images/flags/afghanistan.png', 'AFN'),
  _Country('Oman', 'OM', 'assets/images/flags/oman.png', 'OMR'),
  _Country('UAE', 'AE', 'assets/images/flags/uae.png', 'AED'),
  _Country('Qatar', 'QA', 'assets/images/flags/qatar.png', 'QAR'),
  _Country('KSA', 'SA', 'assets/images/flags/ksa.png', 'SAR'),
  _Country('Syria', 'SY', 'assets/images/flags/syria.png', 'SYP'),
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
  'PKR',
];

class _ClassifiedChildSubcategory {
  final String name;
  final String slug;
  const _ClassifiedChildSubcategory(this.name, this.slug);
}

const _classifiedChildSubcategories =
    <String, List<_ClassifiedChildSubcategory>>{
  'men': [
    _ClassifiedChildSubcategory('Shirts', 'shirts'),
    _ClassifiedChildSubcategory('T-Shirts', 't-shirts'),
    _ClassifiedChildSubcategory('Jeans', 'jeans'),
    _ClassifiedChildSubcategory('Shalwar Kameez', 'shalwar-kameez'),
    _ClassifiedChildSubcategory('Jackets', 'jackets'),
    _ClassifiedChildSubcategory('Kurta', 'kurta'),
    _ClassifiedChildSubcategory('Accessories', 'accessories'),
  ],
  'women': [
    _ClassifiedChildSubcategory('Dresses', 'dresses'),
    _ClassifiedChildSubcategory('Shalwar Kameez', 'shalwar-kameez'),
    _ClassifiedChildSubcategory('Abayas', 'abayas'),
    _ClassifiedChildSubcategory('Tops', 'tops'),
    _ClassifiedChildSubcategory('Jeans', 'jeans'),
    _ClassifiedChildSubcategory('Dupatta/Scarf', 'dupatta-scarf'),
    _ClassifiedChildSubcategory('Accessories', 'accessories'),
  ],
  'kids-fashion': [
    _ClassifiedChildSubcategory('Boys Wear', 'boys-wear'),
    _ClassifiedChildSubcategory('Girls Wear', 'girls-wear'),
    _ClassifiedChildSubcategory('Baby Clothes', 'baby-clothes'),
    _ClassifiedChildSubcategory('School Uniform', 'school-uniform'),
    _ClassifiedChildSubcategory('Party Wear', 'party-wear'),
    _ClassifiedChildSubcategory('Kids Shoes', 'kids-shoes'),
    _ClassifiedChildSubcategory('Accessories', 'accessories'),
  ],
  'bags': [
    _ClassifiedChildSubcategory('Handbags', 'handbags'),
    _ClassifiedChildSubcategory('Backpacks', 'backpacks'),
    _ClassifiedChildSubcategory('School Bags', 'school-bags'),
    _ClassifiedChildSubcategory('Travel Bags', 'travel-bags'),
    _ClassifiedChildSubcategory('Wallets', 'wallets'),
    _ClassifiedChildSubcategory('Clutches', 'clutches'),
    _ClassifiedChildSubcategory('Pouches', 'pouches'),
  ],
  'footwear': [
    _ClassifiedChildSubcategory('Men\'s Shoes', 'mens-shoes'),
    _ClassifiedChildSubcategory('Women\'s Shoes', 'womens-shoes'),
    _ClassifiedChildSubcategory('Kids\' Shoes', 'kids-shoes'),
    _ClassifiedChildSubcategory('Sandals', 'sandals'),
    _ClassifiedChildSubcategory('Boots', 'boots'),
    _ClassifiedChildSubcategory('Sports Shoes', 'sports-shoes'),
    _ClassifiedChildSubcategory('Slippers', 'slippers'),
  ],
  'jewellery': [
    _ClassifiedChildSubcategory('Necklaces', 'necklaces'),
    _ClassifiedChildSubcategory('Earrings', 'earrings'),
    _ClassifiedChildSubcategory('Rings', 'rings'),
    _ClassifiedChildSubcategory('Bracelets', 'bracelets'),
    _ClassifiedChildSubcategory('Bangles', 'bangles'),
    _ClassifiedChildSubcategory('Sets', 'sets'),
    _ClassifiedChildSubcategory('Anklets', 'anklets'),
  ],
  'watches-accessories': [
    _ClassifiedChildSubcategory('Watches', 'watches'),
    _ClassifiedChildSubcategory('Sunglasses', 'sunglasses'),
    _ClassifiedChildSubcategory('Belts', 'belts'),
    _ClassifiedChildSubcategory('Caps & Hats', 'caps-hats'),
    _ClassifiedChildSubcategory('Ties', 'ties'),
    _ClassifiedChildSubcategory('Scarves', 'scarves'),
    _ClassifiedChildSubcategory('Wallets', 'wallets'),
  ],
  'books-sports': [
    _ClassifiedChildSubcategory('Academic Books', 'academic-books'),
    _ClassifiedChildSubcategory('Fiction Books', 'fiction-books'),
    _ClassifiedChildSubcategory('Kids Book', 'kids-book'),
    _ClassifiedChildSubcategory('Exam Preparation', 'exam-preparation'),
    _ClassifiedChildSubcategory('Sports Accessories', 'sports-accessories'),
    _ClassifiedChildSubcategory('Cricket Gear', 'cricket-gear'),
    _ClassifiedChildSubcategory('Fitness Equipment', 'fitness-equipment'),
    _ClassifiedChildSubcategory('Musical Instruments', 'musical-instruments'),
  ],
};

class _DetailRow {
  final TextEditingController keyCtrl;
  final TextEditingController valueCtrl;

  _DetailRow({String key = '', String value = ''})
      : keyCtrl = TextEditingController(text: key),
        valueCtrl = TextEditingController(text: value);

  void dispose() {
    keyCtrl.dispose();
    valueCtrl.dispose();
  }
}

List<_DetailRow> _defaultDetailRows(String category) {
  switch (category.trim().toLowerCase().replaceAll('_', '-')) {
    case 'electronics':
      return [
        _DetailRow(key: 'brand'),
        _DetailRow(key: 'model'),
        _DetailRow(key: 'condition', value: 'Used'),
        _DetailRow(key: 'age'),
        _DetailRow(key: 'usage'),
        _DetailRow(key: 'warranty'),
        _DetailRow(key: 'seller_type', value: 'Individual'),
        _DetailRow(key: 'phone'),
      ];
    case 'furniture':
      return [
        _DetailRow(key: 'brand'),
        _DetailRow(key: 'condition', value: 'Used'),
        _DetailRow(key: 'material'),
        _DetailRow(key: 'color'),
        _DetailRow(key: 'room_type'),
        _DetailRow(key: 'type'),
        _DetailRow(key: 'usage'),
        _DetailRow(key: 'age'),
        _DetailRow(key: 'seller_type', value: 'Individual'),
        _DetailRow(key: 'phone'),
      ];
    case 'classifieds':
      return [
        _DetailRow(key: 'brand'),
        _DetailRow(key: 'condition', value: 'Good'),
        _DetailRow(key: 'age'),
        _DetailRow(key: 'usage'),
        _DetailRow(key: 'seller_type', value: 'Individual'),
        _DetailRow(key: 'phone'),
      ];
    case 'jobs':
      return [
        _DetailRow(key: 'company'),
        _DetailRow(key: 'job_type', value: 'Full-time'),
        _DetailRow(key: 'experience'),
        _DetailRow(key: 'industry'),
        _DetailRow(key: 'education'),
        _DetailRow(key: 'seller_type', value: 'Company'),
        _DetailRow(key: 'phone'),
      ];
    case 'spare-parts':
      return [
        _DetailRow(key: 'make'),
        _DetailRow(key: 'model'),
        _DetailRow(key: 'part_name'),
        _DetailRow(key: 'year'),
        _DetailRow(key: 'mileage'),
        _DetailRow(key: 'condition', value: 'Used'),
        _DetailRow(key: 'seller_type', value: 'Individual'),
        _DetailRow(key: 'phone'),
        _DetailRow(key: 'address'),
      ];
    default:
      return [_DetailRow()];
  }
}

class PostAdScreen extends ConsumerStatefulWidget {
  final String category;
  const PostAdScreen({super.key, required this.category});

  @override
  ConsumerState<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends ConsumerState<PostAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _sellerNameCtrl = TextEditingController();
  bool _forCustomer = false;
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  late final List<_DetailRow> _details;

  _Country _country = _kCountries.first;
  String _currency = 'AFN';
  String _selectedSubcategory = '';
  String _selectedClassifiedChild = '';

  String get _categoryKey =>
      widget.category.trim().toLowerCase().replaceAll('_', '-');

  bool get _isClassified => _categoryKey == 'classifieds';

  @override
  void initState() {
    super.initState();
    _details = _defaultDetailRows(widget.category);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sellProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _cityCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _sellerNameCtrl.dispose();
    for (final row in _details) {
      row.dispose();
    }
    super.dispose();
  }

  String get _categoryLabel {
    switch (widget.category) {
      case 'cars':
        return 'Car';
      case 'properties':
        return 'Property';
      case 'mobiles':
        return 'Mobile';
      case 'electronics':
        return 'Electronics';
      case 'furniture':
        return 'Furniture';
      case 'spare-parts':
      case 'spare_parts':
        return 'Spare Part';
      case 'jobs':
        return 'Job';
      case 'classifieds':
        return 'Classified';
      default:
        return 'Item';
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Select Country',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          ..._kCountries.map(
            (c) => ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  c.flag,
                  width: 32,
                  height: 22,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.flag, size: 22),
                ),
              ),
              title: Text(c.name, style: GoogleFonts.poppins(fontSize: 14)),
              trailing: Text(
                c.currency,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: _country.code == c.code,
              selectedTileColor: AppColors.primaryLight,
              onTap: () {
                setState(() {
                  _country = c;
                });
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Select Currency',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _kCurrencies
                      .map(
                        (cur) => ListTile(
                          title: Text(
                            cur,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: cur == _currency
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: cur == _currency
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.primary, size: 20)
                              : null,
                          onTap: () {
                            setState(() => _currency = cur);
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _buildCategoryData() {
    final result = <String, dynamic>{};
    for (final row in _details) {
      final rawKey = row.keyCtrl.text.trim();
      final value = row.valueCtrl.text.trim();
      if (rawKey.isEmpty || value.isEmpty) continue;

      var key = rawKey
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
      if (key.isEmpty) continue;

      if (result.containsKey(key)) {
        var n = 2;
        while (result.containsKey('${key}_$n')) {
          n++;
        }
        key = '${key}_$n';
      }
      result[key] = value;
    }
    return result;
  }

  String _detailValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  void _setIfEmpty(Map<String, dynamic> data, String key, dynamic value) {
    final text = value?.toString().trim() ?? '';
    final current = data[key]?.toString().trim() ?? '';
    if (current.isEmpty && text.isNotEmpty) data[key] = value;
  }

  void _normalizeCategoryData(Map<String, dynamic> data) {
    data['subcategory'] = _selectedSubcategory;
    data['country'] = _country.name;
    data['city'] = _cityCtrl.text.trim();

    final phone = _detailValue(
      data,
      const ['phone', 'seller_phone', 'contact_phone', 'contact_number'],
    );
    if (phone.isNotEmpty) {
      data['phone'] = phone;
      data['seller_phone'] = phone;
      data['contact_number'] = phone;
    }

    if (_categoryKey == 'classifieds') {
      if (_selectedClassifiedChild.isNotEmpty) {
        data['classified_subcategory'] = _selectedClassifiedChild;
        data['sub_category'] = _selectedClassifiedChild;
        data['subtype'] = _selectedClassifiedChild;
      }
    }

    if (_categoryKey == 'jobs') {
      _setIfEmpty(data, 'industry', _selectedSubcategory);
      _setIfEmpty(data, 'job_category', _selectedSubcategory);
      _setIfEmpty(data, 'seller_type', 'Company');
    }

    if (_categoryKey == 'spare-parts') {
      _setIfEmpty(data, 'make', _selectedSubcategory);
      _setIfEmpty(data, 'brand', data['make']);
      _setIfEmpty(data, 'seller_type', 'Individual');
    }

    if (_categoryKey == 'electronics' ||
        _categoryKey == 'furniture' ||
        _categoryKey == 'classifieds') {
      _setIfEmpty(data, 'seller_type', 'Individual');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final categoryData = _buildCategoryData();
    _normalizeCategoryData(categoryData);

    await ref.read(sellProvider.notifier).createListing(
          category: widget.category,
          baseData: {
            'title': _titleCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
            'currency': _currency,
            'country': _country.name,
            'city': _cityCtrl.text.trim(),
            'subcategory': _selectedSubcategory.isNotEmpty
                ? _selectedSubcategory
                : 'general',
            // Left empty, the repository falls back to the poster's own name.
            'seller_name': _sellerNameCtrl.text.trim(),
          },
          customerPhone: _forCustomer ? _customerPhoneCtrl.text : null,
          customerName: _forCustomer ? _customerNameCtrl.text : null,
          categoryData: categoryData,
        );
  }

  @override
  Widget build(BuildContext context) {
    final sellState = ref.watch(sellProvider);
    final subcategoriesAsync =
        ref.watch(sellSubcategoriesProvider(widget.category));

    ref.listen<SellState>(sellProvider, (prev, next) {
      if (next.success && !(prev?.success ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ad submitted. It will be visible after admin approval.',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(sellProvider.notifier).reset();
        context.pop();
        context.pop();
      }

      final errorChanged = next.error != null && next.error != prev?.error;
      if (errorChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!, style: GoogleFonts.montserrat()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Post $_categoryLabel Ad',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 28 / 15,
            letterSpacing: 0,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoSection(sellState),
              const SizedBox(height: 18),
              Consumer(builder: (context, ref, _) {
                final isStaff = ref.watch(isStaffProvider).value ?? false;
                if (!isStaff) return const SizedBox.shrink();
                return CustomerPostingSection(
                  enabled: _forCustomer,
                  onChanged: (v) => setState(() => _forCustomer = v),
                  nameController: _customerNameCtrl,
                  phoneController: _customerPhoneCtrl,
                );
              }),
              _label('Subcategory'),
              _buildSubcategorySection(subcategoriesAsync),
              const SizedBox(height: 16),
              _label('Country'),
              GestureDetector(
                onTap: _showCountryPicker,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
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
                          color: Colors.black54, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label('Title *'),
              AppTextField(
                controller: _titleCtrl,
                hintText: '${context.l10n.t('e.g.')} $_categoryLabel',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),
              _label('Description'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: context.l10n.t('Describe your listing...'),
                  hintStyle: const TextStyle(color: Colors.black38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              _label('Price'),
              Row(
                children: [
                  GestureDetector(
                    onTap: _showCurrencyPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCCCCCC)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currency,
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down,
                              size: 16, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      controller: _priceCtrl,
                      hintText: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label('City *'),
              AppTextField(
                controller: _cityCtrl,
                hintText: context.l10n.t('e.g. Dubai'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'City is required' : null,
              ),
              const SizedBox(height: 16),
              _label(context.l10n.t('Seller Name')),
              AppTextField(
                controller: _sellerNameCtrl,
                hintText: context.l10n.t('e.g. Ahmed Khan'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label('Extra Details (Dynamic)'),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _details.add(_DetailRow()));
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.l10n.t('Add field')),
                  ),
                ],
              ),
              ...List.generate(_details.length, (index) {
                final row = _details[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: row.keyCtrl,
                          hintText: context.l10n.t('Label (e.g. condition)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          controller: row.valueCtrl,
                          hintText: context.l10n.t('Value (e.g. brand new)'),
                        ),
                      ),
                      if (_details.length > 1)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              final removed = _details.removeAt(index);
                              removed.dispose();
                            });
                          },
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              AppButton(
                label: context.l10n.t('Post Ad'),
                isLoading: sellState.isSubmitting,
                onTap: _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(SellState sellState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E3E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Photos ${sellState.images.length}/10',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (sellState.images.isNotEmpty)
                Text(
                  'First photo will be cover',
                  style:
                      GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (sellState.images.isNotEmpty)
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sellState.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(sellState.images[i].path),
                          width: 82,
                          height: 82,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () =>
                              ref.read(sellProvider.notifier).removeImage(i),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          if (sellState.images.isNotEmpty) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: sellState.images.length >= 10
                      ? null
                      : () => ref.read(sellProvider.notifier).pickFromGallery(),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(context.l10n.t('Gallery')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: sellState.images.length >= 10
                      ? null
                      : () => ref.read(sellProvider.notifier).pickFromCamera(),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: Text(context.l10n.t('Camera')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                _selectedClassifiedChild =
                    (_classifiedChildSubcategories[_selectedSubcategory] ?? [])
                            .isNotEmpty
                        ? _classifiedChildSubcategories[_selectedSubcategory]!
                            .first
                            .slug
                        : '';
              });
            }
          });
        }

        if (subcategories.isEmpty) {
          return Text(
            'No subcategory configured in dashboard for this category.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          );
        }

        final children =
            _classifiedChildSubcategories[_selectedSubcategory] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...subcategories.map((sub) {
              final selected = _selectedSubcategory == sub.slug;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedSubcategory = sub.slug;
                    final childList =
                        _classifiedChildSubcategories[_selectedSubcategory] ??
                            [];
                    _selectedClassifiedChild =
                        _isClassified && childList.isNotEmpty
                            ? childList.first.slug
                            : '';
                  }),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFDDDDDD),
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
            }),
            if (_isClassified && children.isNotEmpty) ...[
              const SizedBox(height: 8),
              _label('Sub Category'),
              ...children.map((child) {
                final selected = _selectedClassifiedChild == child.slug;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedClassifiedChild = child.slug),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : const Color(0xFFDDDDDD),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              child.name,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected
                                    ? AppColors.primary
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle,
                                color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}
