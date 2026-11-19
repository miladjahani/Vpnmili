import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/settings.dart';
import '../models/theme_color.dart';
import '../services/vpn_channel.dart';
import '../state/app_state.dart';
import 'bettbox_widgets.dart';
import 'cf_accounts_page.dart';
import 'chain_proxies_page.dart';
import 'dns_page.dart';
import 'fragments_page.dart';
import 'license_page.dart';
import 'mili_i18n.dart';
import 'mili_toolbox_page.dart';
import 'noises_page.dart';
import 'per_app_page.dart';
import 'routing_page.dart';
import 'settings_page.dart';
import 'tor_bridges_page.dart';

/// Bettbox-style Tools & Settings Hub:
/// Searchable settings bar, visual Theme Preview cards (7 Mili themes),
/// Worker Protocol switcher (VLESS WS / VLESS XHTTP / Trojan WS / Shadowsocks WS),
/// tinted icon badges, and clean rounded Bettbox cards for every native feature.
class MiliBettboxSettingsTab extends StatefulWidget {
  const MiliBettboxSettingsTab({super.key});

  @override
  State<MiliBettboxSettingsTab> createState() => _MiliBettboxSettingsTabState();
}

class _MiliBettboxSettingsTabState extends State<MiliBettboxSettingsTab> {
  String _search = '';

  bool _matches(String fa, String en, [String extra = '']) {
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return fa.toLowerCase().contains(q) ||
        en.toLowerCase().contains(q) ||
        extra.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final d = state.device;
    final p = state.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 106),
      children: [
        // Bettbox-style top search bar
        TextField(
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Symbols.search_rounded, size: 20),
            hintText: MiliLocale.t(
              'جستجو در تنظیمات و ابزارها…',
              'Search settings & tools…',
            ),
            suffixIcon: _search.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Symbols.close_rounded, size: 18),
                    onPressed: () => setState(() => _search = ''),
                  ),
          ),
          onChanged: (v) => setState(() => _search = v.trim()),
        ),
        const SizedBox(height: 14),

        // 1. Worker Protocol Card (VLESS WS / VLESS XHTTP / Trojan WS / Shadowsocks WS)
        if (_matches('پروتکل ورکر', 'Worker Protocol', 'vless xhttp trojan shadowsocks ss')) ...[
          BettboxTileCard(
            title: MiliLocale.t(
              'پروتکل ورکر کلادفلر (VLESS · XHTTP · Trojan · SS)',
              'Cloudflare Worker Protocol',
            ),
            icon: Symbols.hub_rounded,
            watermarkIcon: Symbols.hub_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final proto in const [
                  ('vless_ws', 'VLESS · WS'),
                  ('vless_xhttp', 'VLESS · XHTTP'),
                  ('trojan_ws', 'Trojan · WS'),
                  ('shadowsocks_ws', 'Shadowsocks · WS'),
                ])
                  ChoiceChip(
                    selected: d.workerProtocol == proto.$1,
                    label: Text(proto.$2),
                    visualDensity: VisualDensity.compact,
                    onSelected: state.isBusy
                        ? null
                        : (_) {
                            state.write('device.connection.workerProtocol', proto.$1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  MiliLocale.t(
                                    'پروتکل ورکر روی ${proto.$2} تنظیم شد',
                                    'Worker protocol set to ${proto.$2}',
                                  ),
                                ),
                              ),
                            );
                          },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 2. Bettbox Visual Appearance & Theme Cards
        if (_matches('ظاهر و تم و زبان', 'Appearance Theme Language', 'dark light neon')) ...[
          BettboxTileCard(
            title: MiliLocale.t('ظاهر، زبان و تم‌ها', 'Appearance, Language & Themes'),
            icon: Symbols.palette_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Row
                Row(
                  children: [
                    Icon(Symbols.translate_rounded, size: 19, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        MiliLocale.t('زبان برنامه', 'Language'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      segments: const [
                        ButtonSegment(value: 'fa', label: Text('فارسی')),
                        ButtonSegment(value: 'en', label: Text('EN')),
                      ],
                      selected: {MiliLocale.code.value},
                      onSelectionChanged: (s) => MiliLocale.setLang(s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Theme Mode Row
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: state.themeMode,
                  builder: (context, mode, _) => Row(
                    children: [
                      Icon(Symbols.dark_mode_rounded, size: 19, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          MiliLocale.t('حالت نمایش', 'Theme Mode'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text(MiliLocale.t('تیره', 'Dark')),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text(MiliLocale.t('روشن', 'Light')),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text(MiliLocale.t('خودکار', 'Auto')),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (s) => state.setThemeMode(s.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Bettbox-style visual Theme Preview Cards
                ValueListenableBuilder<ThemeColor>(
                  valueListenable: state.themeColor,
                  builder: (context, selected, _) => SizedBox(
                    height: 76,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final c in ThemeColor.values)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => state.setThemeColor(c),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 108,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: c.darkCard,
                                  border: Border.all(
                                    color: selected == c
                                        ? c.seed
                                        : c.seed.withValues(alpha: 0.25),
                                    width: selected == c ? 2.0 : 0.9,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: c.seed,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: c.accent,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (selected == c)
                                          Icon(
                                            Symbols.check_circle_rounded,
                                            size: 15,
                                            color: c.seed,
                                          ),
                                      ],
                                    ),
                                    Text(
                                      c.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFEAF7EE),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 3. Core, Accounts & Routing Section (Bettbox Tools List)
        BettboxTileCard(
          title: MiliLocale.t('اکانت‌ها، زنجیره و هسته', 'Accounts, Chains & Core'),
          icon: Symbols.dns_rounded,
          contentPadding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              if (_matches('جعبه‌ابزار تست سرعت پینگ', 'Toolbox Speed Test Unlock Ping DNS'))
                _BettboxRow(
                  icon: Symbols.construction_rounded,
                  title: MiliLocale.t('جعبه‌ابزار شبکه (تست سرعت · بازگشایی · پینگ · DNS)', 'Network Toolbox'),
                  subtitle: MiliLocale.t(
                    'تست سرعت، بررسی بازگشایی سرویس‌ها، موقعیت آی‌پی، پینگ و DoH',
                    'Speed test, Media/AI unlock, IP lookup, TCP ping & DNS query',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MiliToolboxPage()),
                  ),
                ),
              if (_matches('کلادفلر ورکر', 'Cloudflare Accounts Worker'))
                _BettboxRow(
                  icon: Symbols.cloud_rounded,
                  title: MiliLocale.t('حساب‌های کلادفلر و ورکرها', 'Cloudflare Accounts'),
                  subtitle: MiliLocale.t(
                    '${state.cfAccounts.length} حساب ذخیره شده · مدیریت و استقرار مجدد',
                    '${state.cfAccounts.length} saved account(s) · deploy & manage',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CfAccountsPage()),
                  ),
                ),
              if (_matches('زنجیره پروکسی', 'Chain Proxies'))
                _BettboxRow(
                  icon: Symbols.link_rounded,
                  title: MiliLocale.t('پروکسی‌های زنجیره‌ای', 'Chain Proxies'),
                  subtitle: MiliLocale.t(
                    '${p.chains.length} کانفیگ وارد شده (VLESS, Trojan, SS, WG)',
                    '${p.chains.length} imported config(s)',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChainProxiesPage()),
                  ),
                ),
              if (_matches('فرگمنت', 'TCP Fragments'))
                _BettboxRow(
                  icon: Symbols.broken_image_rounded,
                  title: MiliLocale.t('تنظیمات فرگمنت TCP', 'TCP Fragments'),
                  subtitle: MiliLocale.t(
                    'تکه‌تکه‌سازی بسته‌ها برای عبور از DPI',
                    'Split TLS ClientHello to bypass DPI',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FragmentsPage()),
                  ),
                ),
              if (_matches('نویز مبهم‌سازی', 'UDP Noises Obfuscation'))
                _BettboxRow(
                  icon: Symbols.graphic_eq_rounded,
                  title: MiliLocale.t('نویز UDP و مبهم‌سازی', 'UDP Noises'),
                  subtitle: MiliLocale.t(
                    'تنظیمات نویز برای WARP و MASQUE',
                    'UDP obfuscation tuning for WARP & MASQUE',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NoisesPage()),
                  ),
                ),
              if (_matches('مسیریابی ایران', 'Routing Rules'))
                _BettboxRow(
                  icon: Symbols.alt_route_rounded,
                  title: MiliLocale.t('مسیریابی و قوانین ایران', 'Routing & Rules'),
                  subtitle: MiliLocale.t(
                    'عبور مستقیم سایت‌های ایرانی و مسدودسازی تبلیغات',
                    'Bypass local domains, LAN & ad blocking',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RoutingPage(
                        title: MiliLocale.t('مسیریابی و عبور مستقیم', 'Bypass Rules'),
                        group: 'bypass',
                        labels: const {
                          'lan': 'LAN',
                          'ir': 'Iran',
                          'cn': 'China',
                          'ru': 'Russia',
                          'openai': 'OpenAI',
                        },
                        domainHint: 'example.ir, geosite:ir',
                      ),
                    ),
                  ),
                ),
              if (_matches('تفکیک برنامه', 'Per-App Proxy'))
                _BettboxRow(
                  icon: Symbols.apps_rounded,
                  title: MiliLocale.t('تفکیک برنامه‌ها (Per-App)', 'Per-App Proxy'),
                  subtitle: MiliLocale.t(
                    'انتخاب برنامه‌های عبوری یا مستثنی از VPN',
                    'Include or exclude specific Android apps',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PerAppPage()),
                  ),
                ),
              if (_matches('تور پل', 'Tor Bridges'))
                _BettboxRow(
                  icon: Symbols.vpn_key_rounded,
                  title: MiliLocale.t('پل‌های شبکه تور (Tor)', 'Tor Bridges'),
                  subtitle: MiliLocale.t(
                    'مدیریت پل‌های Snowflake و obfs4',
                    'Manage Snowflake, WebTunnel & custom bridges',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TorBridgesPage()),
                  ),
                ),
              if (_matches('DNS سرور', 'DNS Servers'))
                _BettboxRow(
                  icon: Symbols.dns_rounded,
                  title: MiliLocale.t('سرورهای DNS و DoH', 'DNS Servers'),
                  subtitle: MiliLocale.t(
                    'انتخاب سرورهای DoH / DoQ / UDP',
                    'Manage encrypted DoH, DoQ & local DNS',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DnsPage()),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4. Advanced Full Settings, Backup & Support
        BettboxTileCard(
          title: MiliLocale.t('پیشرفته و پشتیبانی', 'Advanced & Support'),
          icon: Symbols.settings_applications_rounded,
          contentPadding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              _BettboxRow(
                icon: Symbols.tune_rounded,
                title: MiliLocale.t(
                  'همه تنظیمات ریز و تخصصی (VLESS / WARP / LAN / Export)',
                  'All Granular Settings (VLESS / WARP / LAN / Export)',
                ),
                subtitle: MiliLocale.t(
                  'دسترسی به تمام گزینه‌های تخصصی، MTU، ECH، Custom CDN و بکاپ',
                  'Full access to MTU, ECH, Custom CDN, LAN sharing & backup',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
              ),
              _BettboxRow(
                icon: Symbols.support_agent_rounded,
                title: MiliLocale.t('پشتیبانی و جامعه MiliConfig', 'MiliConfig Community'),
                subtitle: '@miliconfig',
                onTap: () => VpnChannel.openUrl('https://t.me/miliconfig'),
              ),
              _BettboxRow(
                icon: Symbols.copyright_rounded,
                title: MiliLocale.t('مجوز متن‌باز', 'Open Source License'),
                subtitle: 'GNU GPL v3.0',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LicensePageView()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BettboxRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BettboxRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: scheme.primary.withValues(alpha: 0.13),
        ),
        child: Icon(icon, size: 19, color: scheme.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
      ),
      trailing: Icon(
        Symbols.chevron_right_rounded,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
