import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../providers/sell_provider.dart';
import '../widgets/customer_posting_section.dart';
import '../providers/staff_provider.dart';

const _kBlue = Color(0xFF2258A8);

const _kPropertyTypes = [
  'House',
  'Apartment',
  'Villa',
  'Office',
  'Shop',
  'Land',
];

const _kPurposes = ['For Sale', 'For Rent'];
const _kFurnishing = ['Furnished', 'Semi Furnished', 'Unfurnished'];
const _kBedBath = ['Studio', '1', '2', '3', '4', '5+'];
const _kCurrencies = ['AFN', 'USD', 'AED', 'OMR', 'QAR', 'SAR', 'SYP'];

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

class PostPropertyScreen extends ConsumerStatefulWidget {
  const PostPropertyScreen({super.key});

  @override
  ConsumerState<PostPropertyScreen> createState() => _PostPropertyScreenState();
}

class _PostPropertyScreenState extends ConsumerState<PostPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _forCustomer = false;
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();

  final _addressCtrl = TextEditingController();
  final _amenitiesCtrl = TextEditingController();

  String _propertyType = '';
  String _purpose = '';
  String _furnishing = '';
  String _beds = '';
  String _baths = '';
  String _currency = 'AFN';
  _Country _country = _kCountries.first;

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _contactNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _amenitiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_propertyType.isEmpty) {
      _showError('Please select property type');
      return;
    }
    if (_purpose.isEmpty) {
      _showError('Please select purpose');
      return;
    }
    if (_cityCtrl.text.trim().isEmpty) {
      _showError('Please enter city');
      return;
    }

    await ref.read(sellProvider.notifier).createListing(
      category: 'properties',
      baseData: {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'currency': _currency,
        'city': _cityCtrl.text.trim(),
        'country': _country.name,
        'seller_name': _contactNameCtrl.text.trim(),
        'subcategory': _purpose.toLowerCase() == 'for rent'
            ? 'for-rent-residential'
            : 'for-sale-residential',
      },
      customerPhone: _forCustomer ? _customerPhoneCtrl.text : null,
      customerName: _forCustomer ? _customerNameCtrl.text : null,
      categoryData: {
        'property_type': _propertyType,
        'purpose': _purpose,
        'furnishing': _furnishing,
        'bedrooms': _beds,
        'bathrooms': _baths,
        'area': _areaCtrl.text.trim(),
        'country': _country.name,
        'city': _cityCtrl.text.trim(),
        'contact_name': _contactNameCtrl.text.trim(),
        'contact_phone': _phoneCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'seller_phone': _phoneCtrl.text.trim(),
        'contact_number': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'amenities': _amenitiesCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPicker(
      String title, List<String> options, ValueChanged<String> onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
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
                itemBuilder: (_, i) => ListTile(
                  title: Text(context.l10n.t(options[i]),
                      style: GoogleFonts.poppins(fontSize: 14)),
                  onTap: () {
                    onSelect(options[i]);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sell = ref.watch(sellProvider);

    ref.listen(sellProvider, (_, next) {
      if (next.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Ad submitted. It will be visible after admin approval.',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(sellProvider.notifier).reset();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
      if (next.error != null) _showError(next.error!);
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
        title: Text(
          'Post Property Ad',
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 96),
          child: Column(
            children: [
              _PhotoSection(sell: sell),
              const SizedBox(height: 8),
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
              _Section(
                title: 'Basic Info',
                children: [
                  _Field(
                    label: 'Title *',
                    child: _textInput(
                      _titleCtrl,
                      'e.g. Apartment 2BHK in Kabul',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Title is required'
                          : null,
                    ),
                  ),
                  _Field(
                    label: 'Description *',
                    child: _textInput(
                      _descCtrl,
                      'Write details about this property...',
                      maxLines: 4,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Description is required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Section(
                title: 'Property Details',
                children: [
                  _Field(
                    label: 'Property Type *',
                    child: _dropdown(
                        _propertyType.isEmpty
                            ? 'Select property type'
                            : _propertyType,
                        () => _showPicker('Property Type', _kPropertyTypes,
                            (v) => setState(() => _propertyType = v))),
                  ),
                  _Field(
                    label: 'Purpose *',
                    child: _chipGroup(_kPurposes, _purpose,
                        (v) => setState(() => _purpose = v)),
                  ),
                  _Field(
                    label: 'Furnishing',
                    child: _dropdown(
                      _furnishing.isEmpty ? 'Select furnishing' : _furnishing,
                      () => _showPicker('Furnishing', _kFurnishing,
                          (v) => setState(() => _furnishing = v)),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'Bedrooms',
                          child: _dropdown(
                            _beds.isEmpty ? 'Select' : _beds,
                            () => _showPicker('Bedrooms', _kBedBath,
                                (v) => setState(() => _beds = v)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Field(
                          label: 'Bathrooms',
                          child: _dropdown(
                            _baths.isEmpty ? 'Select' : _baths,
                            () => _showPicker('Bathrooms', _kBedBath,
                                (v) => setState(() => _baths = v)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _Field(
                    label: 'Area (sqft)',
                    child: _textInput(_areaCtrl, 'e.g. 1200',
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Section(
                title: 'Price & Location',
                children: [
                  _Field(
                    label: 'Price *',
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showPicker('Currency', _kCurrencies,
                              (v) => setState(() => _currency = v)),
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
                                    color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _textInput(
                            _priceCtrl,
                            '0',
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Price is required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Field(
                    label: 'Country',
                    child: GestureDetector(
                      onTap: () => _showPicker(
                          'Country', _kCountries.map((e) => e.name).toList(),
                          (v) {
                        setState(() {
                          _country = _kCountries.firstWhere((c) => c.name == v);
                        });
                      }),
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
                              child: Text(_country.name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14, color: Colors.black87)),
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
                      _cityCtrl,
                      'e.g. Kabul, Dubai',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'City is required'
                          : null,
                    ),
                  ),
                  _Field(
                    label: 'Address',
                    child: _textInput(
                      _addressCtrl,
                      'e.g. Dubai Marina Walk, Dubai',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Section(
                title: 'Contact & Amenities',
                children: [
                  _Field(
                    label: 'Seller Name',
                    child: _textInput(
                      _contactNameCtrl,
                      'e.g. Ahmed Khan',
                    ),
                  ),
                  _Field(
                    label: 'Phone',
                    child: _textInput(
                      _phoneCtrl,
                      'e.g. +971501234567',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  _Field(
                    label: 'Amenities (comma separated)',
                    child: _textInput(
                      _amenitiesCtrl,
                      'Parking, Balcony, Gym, Pool, Security, Elevator',
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            ),
            child: sell.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
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

  Widget _textInput(
    TextEditingController controller,
    String hint, {
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
      ),
    );
  }

  Widget _dropdown(String value, VoidCallback onTap) {
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
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isPlaceholder ? Colors.black38 : Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 20, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  Widget _chipGroup(
      List<String> options, String selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? _kBlue : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? _kBlue : const Color(0xFFDDDDDD)),
            ),
            child: Text(
              opt,
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

class _PhotoSection extends ConsumerWidget {
  final SellState sell;
  const _PhotoSection({required this.sell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(sellProvider.notifier);
    final images = sell.images;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(context.l10n.t('Photos'),
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text('${images.length}/10',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
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
                            color: _kBlue.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined,
                          color: _kBlue, size: 28),
                    ),
                  ),
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
                              fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => notifier.removeImage(idx),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
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
        ],
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context, SellNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _kBlue),
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
    );
  }
}

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
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

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
