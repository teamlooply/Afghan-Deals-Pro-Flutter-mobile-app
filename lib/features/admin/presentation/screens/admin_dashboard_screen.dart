import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../providers/admin_dynamic_provider.dart';
import '../../../../core/router/route_names.dart';
import 'admin_filter_options_screen.dart';
import 'admin_regions_screen.dart';
import 'admin_price_settings_screen.dart';
import 'admin_whatsapp_screen.dart';

const _kBlue = Color(0xFF2258A8);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Admin Dashboard',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminStatsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats row ─────────────────────────────────────────
              statsAsync.when(
                loading: () => const SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator(color: _kBlue)),
                ),
                error: (_, __) => const SizedBox(),
                data: (stats) => Row(
                  children: [
                    _StatCard('Total', stats.totalListings.toString(), Icons.list_alt_outlined, Colors.indigo),
                    const SizedBox(width: 10),
                    _StatCard('Active', stats.activeListings.toString(), Icons.check_circle_outline, Colors.green),
                    const SizedBox(width: 10),
                    _StatCard('Filters', stats.filterOptions.toString(), Icons.tune, Colors.orange),
                    const SizedBox(width: 10),
                    _StatCard('Regions', stats.regions.toString(), Icons.location_on_outlined, Colors.teal),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionLabel('Dynamic Management'),
              const SizedBox(height: 12),

              // ── Management cards grid ──────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _AdminCard(
                    icon: Icons.tune,
                    title: 'Filter Options',
                    subtitle: 'Conditions, ages,\nwarranties, types...',
                    color: const Color(0xFF5C6BC0),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminFilterOptionsScreen()),
                    ),
                  ),
                  _AdminCard(
                    icon: Icons.location_on,
                    title: 'Regions & Cities',
                    subtitle: 'Manage locations\nfor all categories',
                    color: const Color(0xFF26A69A),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminRegionsScreen()),
                    ),
                  ),
                  _AdminCard(
                    icon: Icons.price_change_outlined,
                    title: 'Price Settings',
                    subtitle: 'Max price range\nper category',
                    color: const Color(0xFFF57C00),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminPriceSettingsScreen()),
                    ),
                  ),
                  _AdminCard(
                    icon: Icons.category_outlined,
                    title: 'Subcategories',
                    subtitle: 'Sort & manage\ncategory listings',
                    color: const Color(0xFF8D6E63),
                    onTap: () => context.push(RouteNames.adminSubcategories),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _sectionLabel('Content Management'),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _AdminCard(
                    icon: Icons.dashboard_outlined,
                    title: 'Classifieds',
                    subtitle: 'Manage classified\nlistings & ads',
                    color: const Color(0xFF42A5F5),
                    onTap: () => context.push(RouteNames.adminClassifieds),
                  ),
                  _AdminCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'All Chats',
                    subtitle: 'View & monitor\nuser chats',
                    color: const Color(0xFFEC407A),
                    onTap: () => context.push(RouteNames.adminChats),
                  ),
                  _AdminCard(
                    icon: Icons.phone_in_talk_outlined,
                    title: 'WhatsApp Numbers',
                    subtitle: 'Add numbers for\nsellers without one',
                    color: const Color(0xFF25D366),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminWhatsAppScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _sectionLabel('Database Setup'),
              const SizedBox(height: 12),
              _SetupCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
          letterSpacing: 0.5));
}

// ── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}

// ── Admin Card ────────────────────────────────────────────────────────────────
class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.black45, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

// ── SQL Setup Card ────────────────────────────────────────────────────────────
class _SetupCard extends StatefulWidget {
  @override
  State<_SetupCard> createState() => _SetupCardState();
}

class _SetupCardState extends State<_SetupCard> {
  bool _expanded = false;

  static const _sql = '''
CREATE TABLE IF NOT EXISTS filter_options (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  category TEXT NOT NULL,
  filter_type TEXT NOT NULL,
  value TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS regions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  country TEXT NOT NULL DEFAULT 'Afghanistan',
  region_name TEXT NOT NULL,
  cities TEXT[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  category TEXT NOT NULL,
  setting_key TEXT NOT NULL,
  setting_value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(category, setting_key)
);

ALTER TABLE filter_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_filter_options" ON filter_options FOR SELECT USING (true);
CREATE POLICY "public_read_regions" ON regions FOR SELECT USING (true);
CREATE POLICY "public_read_app_settings" ON app_settings FOR SELECT USING (true);
''';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.code, color: _kBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Supabase SQL Setup',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.black45, size: 20),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _sql.trim(),
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFFCDD6F4),
                      height: 1.6),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                'Run this SQL in Supabase → SQL Editor before using admin features.',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
