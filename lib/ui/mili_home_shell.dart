import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/cf_account.dart';
import '../models/settings.dart';
import '../services/chain_proxy.dart';
import '../services/mili_ip_pool.dart';
import '../services/mili_live_scanner.dart';
import '../services/mili_panel_client.dart';
import '../services/my_ip.dart';
import '../services/scanner_channel.dart';
import '../services/vpn_channel.dart';
import '../services/xray_config.dart';
import '../state/app_state.dart';
import 'bettbox_widgets.dart';
import 'cf_accounts_page.dart';
import 'chain_proxies_page.dart';
import 'cloudflare_scanner_page.dart';
import 'config_view_page.dart';
import 'format.dart';
import 'log_page.dart';
import 'mili_bettbox_settings.dart';
import 'mili_i18n.dart';
import 'mili_logo.dart';
import 'mili_toolbox_page.dart';
import 'theme.dart';

const _tabular = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
const _activeGreen = Color(0xFF34D399);

/// MiliConfig v2.0.0 — Full Bettbox Architecture:
/// 1) Dashboard: StartButton Hero, Live non-freezing Bezier Speed Chart,
///    Daily Cloudflare Worker Requests Quota, Network Detection, Traffic Usage, Quick Options
/// 2) Nodes (Proxies): Bettbox-style 2-column grid for Worker Deployments,
///    Protocols (VLESS WS / XHTTP / Trojan / SS), Built-in Cores (WARP/MASQUE/Psiphon/Tor),
///    Chain Proxies, and Panel Sync
/// 3) Scanner & 696 Pool: Built-in Live TCP Ping Scanner + Native Go REAL Tunnel Scanners
///    + 696 IP Pool usable as BOTH Clean IP & ProxyIP
/// 4) Tools & Settings: Full Bettbox Settings Hub
class MiliHomeShell extends StatefulWidget {
  const MiliHomeShell({super.key});

  @override
  State<MiliHomeShell> createState() => _MiliHomeShellState();
}

class _MiliHomeShellState extends State<MiliHomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<String>(
      valueListenable: MiliLocale.code,
      builder: (context, _, __) => Scaffold(
        extendBody: true,
        appBar: AppBar(
          titleSpacing: 16,
          title: Row(
            children: [
              const MiliShieldLogo(size: 26),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  'MiliConfig',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 0.2,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: MiliLocale.t('گزارش‌ها', 'Logs'),
              icon: const Icon(Symbols.terminal_rounded, size: 21),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LogPage()),
              ),
            ),
            IconButton(
              tooltip: MiliLocale.t('کانفیگ Xray', 'Config JSON'),
              icon: const Icon(Symbols.data_object_rounded, size: 21),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConfigViewPage()),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_tab),
            child: switch (_tab) {
              0 => _BettboxDashboardTab(onJumpTab: (i) => setState(() => _tab = i)),
              1 => const _BettboxNodesTab(),
              2 => const _MiliScannerTab(),
              _ => const MiliBettboxSettingsTab(),
            },
          ),
        ),
        bottomNavigationBar: BettboxFloatingNavBar(
          selectedIndex: _tab,
          onChanged: (i) => setState(() => _tab = i),
          items: [
            (
              icon: Symbols.space_dashboard_rounded,
              label: MiliLocale.t('داشبورد', 'Dashboard'),
            ),
            (
              icon: Symbols.hub_rounded,
              label: MiliLocale.t('نودها', 'Nodes'),
            ),
            (
              icon: Symbols.radar_rounded,
              label: MiliLocale.t('اسکنر', 'Scanner'),
            ),
            (
              icon: Symbols.tune_rounded,
              label: MiliLocale.t('ابزارها', 'Tools'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 1: Bettbox Dashboard (StartButton, Live Chart, Daily Worker Requests,
// Network Detection, Traffic Usage, Quick Options)
// ---------------------------------------------------------------------------

class _BettboxDashboardTab extends StatefulWidget {
  final ValueChanged<int> onJumpTab;
  const _BettboxDashboardTab({required this.onJumpTab});

  @override
  State<_BettboxDashboardTab> createState() => _BettboxDashboardTabState();
}

class _BettboxDashboardTabState extends State<_BettboxDashboardTab> {
  static const _dailyLimit = 100000;
  Timer? _ticker;
  final List<double> _speedHistory = List<double>.filled(24, 0, growable: true);
  int _chartRev = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final state = AppScope.read(context);
      final totalSpeed = (state.downSpeed + state.upSpeed).toDouble();
      _speedHistory.add(totalSpeed);
      if (_speedHistory.length > 24) _speedHistory.removeAt(0);
      _chartRev++;
      if (state.isConnected || totalSpeed > 0 || _speedHistory.any((v) => v > 0)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _modeName(ConnectionMode m) => switch (m) {
    ConnectionMode.worker => MiliLocale.t('ورکر', 'Worker'),
    ConnectionMode.warp => 'WARP',
    ConnectionMode.masque => 'MASQUE',
    ConnectionMode.serverless => MiliLocale.t('سرورلس', 'Serverless'),
    ConnectionMode.psiphon => MiliLocale.t('سایفون', 'Psiphon'),
    ConnectionMode.tor => MiliLocale.t('تور', 'Tor'),
  };

  String _workerProtoLabel(String p) => switch (p) {
    'vless_xhttp' => 'XHTTP',
    'trojan_ws' => 'Trojan',
    'shadowsocks_ws' => 'SS',
    _ => 'VLESS',
  };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final connected = state.isConnected;
    final busy = state.isBusy;
    final failed = state.status == VpnStatus.disconnected && state.error != null;

    final elapsed = state.connectedAt == null
        ? '00:00:00'
        : formatDuration(DateTime.now().difference(state.connectedAt!));
    final myIp = state.myIps?.other ?? state.myIps?.cloudflare;
    final usage = state.usage;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 102),
      children: [
        if (state.needsReconnect)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BettboxTileCard(
              title: MiliLocale.t('تغییر تنظیمات', 'Settings Changed'),
              icon: Symbols.sync_rounded,
              borderColor: scheme.primary,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      MiliLocale.t(
                        'برای اعمال تغییرات، دوباره متصل شوید.',
                        'Reconnect to apply your updated settings.',
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: state.reconnect,
                    child: Text(MiliLocale.t('اعمال', 'Apply')),
                  ),
                ],
              ),
            ),
          ),

        // 1. Bettbox StartButton Hero Tile
        BettboxTileCard(
          title: MiliLocale.t('وضعیت هسته و اتصال', 'Core & Connection'),
          icon: Symbols.power_settings_new_rounded,
          watermarkIcon: connected ? Symbols.verified_user_rounded : Symbols.shield_rounded,
          borderColor: connected
              ? _activeGreen.withValues(alpha: 0.6)
              : (failed ? scheme.error.withValues(alpha: 0.6) : null),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          switch (state.status) {
                            VpnStatus.connected => MiliLocale.t('متصل', 'Running'),
                            VpnStatus.connecting => MiliLocale.t('در حال اتصال…', 'Starting…'),
                            VpnStatus.disconnecting => MiliLocale.t('در حال قطع…', 'Stopping…'),
                            VpnStatus.disconnected when failed => MiliLocale.t('خطا در اتصال', 'Failed'),
                            VpnStatus.disconnected => MiliLocale.t('متوقف', 'Stopped'),
                          },
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: connected
                                ? _activeGreen
                                : (failed ? scheme.error : scheme.onSurface),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          connected
                              ? elapsed
                              : (failed && state.error != null
                                    ? state.error!
                                    : (state.exitDetail ??
                                          MiliLocale.t(
                                            'برای شروع اتصال دکمه را لمس کنید',
                                            'Tap button to start tunnel',
                                          ))),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _tabular.copyWith(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      state.toggle();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: connected ? _activeGreen : scheme.primary,
                      ),
                      child: Center(
                        child: busy
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: scheme.onPrimary,
                                ),
                              )
                            : Icon(
                                connected
                                    ? Symbols.stop_rounded
                                    : Symbols.play_arrow_rounded,
                                size: 30,
                                color: scheme.onPrimary,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  BettboxChip(
                    icon: Symbols.alt_route_rounded,
                    label: state.mode == ConnectionMode.worker
                        ? '${_modeName(state.mode)} · ${_workerProtoLabel(state.device.workerProtocol)}'
                        : _modeName(state.mode),
                    active: true,
                    onTap: () => widget.onJumpTab(1),
                  ),
                  BettboxChip(
                    icon: Symbols.vpn_lock_rounded,
                    label: state.device.appMode == AppMode.proxy
                        ? MiliLocale.t('پروکسی', 'Proxy')
                        : 'VPN',
                    active: state.device.appMode == AppMode.vpn,
                    onTap: state.isBusy
                        ? null
                        : () => state.setAppMode(
                              state.device.appMode == AppMode.vpn
                                  ? AppMode.proxy
                                  : AppMode.vpn,
                            ),
                  ),
                  BettboxChip(
                    icon: Symbols.exit_to_app_rounded,
                    label: '${MiliLocale.t("خروجی", "Exit")}: ${state.exitNode.name}',
                    onTap: state.isBusy
                        ? null
                        : () {
                            final nodes = [
                              ExitNode.worker,
                              if (state.usableChains.isNotEmpty) ExitNode.chain,
                              ExitNode.psiphon,
                              ExitNode.tor,
                            ];
                            final idx = (nodes.indexOf(state.exitNode) + 1) % nodes.length;
                            state.setExitNode(nodes[idx]);
                          },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Live Non-Freezing Network Speed Card
        BettboxTileCard(
          title: MiliLocale.t('سرعت شبکه', 'Network Speed'),
          icon: Symbols.speed_rounded,
          watermarkIcon: Symbols.speed_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Symbols.arrow_downward_rounded, size: 17, color: scheme.primary),
                  const SizedBox(width: 3),
                  Text(
                    '${formatBytes(state.downSpeed)}/s',
                    style: _tabular.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(Symbols.arrow_upward_rounded, size: 15, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text(
                    '${formatBytes(state.upSpeed)}/s',
                    style: _tabular.copyWith(
                      fontSize: 13.5,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              BettboxLineChart(
                values: List<double>.of(_speedHistory),
                revision: _chartRev,
                color: connected ? _activeGreen : scheme.primary,
                height: 56,
              ),
            ],
          ),
        ),

        // 3. Daily Worker Requests Quota Card (restored!)
        if (state.worker != null) ...[
          const SizedBox(height: 12),
          BettboxTileCard(
            title: MiliLocale.t(
              'سهمیه درخواست روزانه ورکر (۲۴ ساعت)',
              'Worker Daily Requests (24h)',
            ),
            icon: Symbols.cloud_done_rounded,
            watermarkIcon: Symbols.bar_chart_rounded,
            actions: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: state.loadingUsage
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Symbols.refresh_rounded, size: 18),
                onPressed: state.loadingUsage ? null : state.refreshUsage,
              ),
            ],
            child: usage != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            formatCount(usage.total),
                            style: _tabular.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            ' / ${formatCount(_dailyLimit)}',
                            style: _tabular.copyWith(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            MiliLocale.t(
                              'باقی‌مانده: ${formatCount((_dailyLimit - usage.total).clamp(0, _dailyLimit))}',
                              'Left: ${formatCount((_dailyLimit - usage.total).clamp(0, _dailyLimit))}',
                            ),
                            style: _tabular.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: usage.total > 85000
                                  ? scheme.error
                                  : _activeGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          value: (usage.total / _dailyLimit).clamp(0.0, 1.0),
                          backgroundColor: scheme.surfaceContainerHigh,
                          color: usage.total > 85000 ? scheme.error : scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        MiliLocale.t(
                          'این ورکر: ${formatCount(usage.worker)} درخواست',
                          'This worker: ${formatCount(usage.worker)} requests',
                        ),
                        style: _tabular.copyWith(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : Text(
                    state.usageError ??
                        (state.loadingUsage
                            ? MiliLocale.t('در حال دریافت آمار…', 'Loading usage…')
                            : MiliLocale.t(
                                'برای مشاهده سهمیه روزانه دکمه بروزرسانی را بزنید',
                                'Tap refresh to fetch 24h Cloudflare request quota',
                              )),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: state.usageError != null
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ],

        const SizedBox(height: 12),

        // 4. 2-Column Row: Network Detection + Traffic Usage
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BettboxTileCard(
                title: MiliLocale.t('تشخیص شبکه', 'Network'),
                icon: Symbols.language_rounded,
                watermarkEmoji: myIp?.country != null
                    ? countryFlag(myIp!.country!)
                    : null,
                watermarkIcon: myIp?.country == null ? Symbols.public_rounded : null,
                onTap: connected
                    ? () {
                        state.testPing();
                        state.refreshMyIps();
                      }
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.pinging
                          ? '…'
                          : (state.pingMs != null
                                ? '${state.pingMs} ms'
                                : MiliLocale.t('تست پینگ', 'Tap ping')),
                      style: _tabular.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: state.pingMs != null ? _activeGreen : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      myIp == null
                          ? MiliLocale.t('آی‌پی خروج', 'Exit IP')
                          : '${countryFlag(myIp.country ?? '')} ${myIp.ip}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _tabular.copyWith(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BettboxTileCard(
                title: MiliLocale.t('مصرف ترافیک', 'Traffic Usage'),
                icon: Symbols.data_usage_rounded,
                watermarkIcon: Symbols.data_usage_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatBytes(state.totalDown + state.totalUp),
                      style: _tabular.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '↓ ${formatBytes(state.totalDown)}  ↑ ${formatBytes(state.totalUp)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _tabular.copyWith(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 5. 2-Column Quick Options
        Row(
          children: [
            Expanded(
              child: BettboxTileCard(
                title: MiliLocale.t('فرگمنت / مبهم‌سازی', 'Anti-DPI'),
                icon: Symbols.security_rounded,
                contentPadding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.variant != ConnectionVariant.normal
                          ? MiliLocale.t('فعال', 'On')
                          : MiliLocale.t('عادی', 'Off'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: state.variant != ConnectionVariant.normal
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    Switch(
                      value: state.variant != ConnectionVariant.normal,
                      onChanged: state.isBusy
                          ? null
                          : (on) {
                              if (state.mode == ConnectionMode.warp) {
                                state.setVariant(
                                  on
                                      ? ConnectionVariant.obfuscated
                                      : ConnectionVariant.normal,
                                );
                              } else {
                                state.setVariant(
                                  on
                                      ? ConnectionVariant.fragment
                                      : ConnectionVariant.normal,
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BettboxTileCard(
                title: 'IPv6',
                icon: Symbols.counter_6_rounded,
                contentPadding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.profile.general.enableIpv6
                          ? MiliLocale.t('فعال', 'On')
                          : MiliLocale.t('خاموش', 'Off'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: state.profile.general.enableIpv6
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    Switch(
                      value: state.profile.general.enableIpv6,
                      onChanged: (v) => state.write('general.enableIpv6', v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 6. Bettbox Toolbox Shortcut Card (Speed Test, Unlock, IP Lookup, Ping, DNS)
        BettboxTileCard(
          title: MiliLocale.t('جعبه‌ابزار شبکه (Bettbox Toolbox)', 'Network Toolbox'),
          icon: Symbols.construction_rounded,
          watermarkIcon: Symbols.construction_rounded,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BettboxChip(
                icon: Symbols.speed_rounded,
                label: MiliLocale.t('تست سرعت', 'Speed Test'),
                active: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MiliToolboxPage(initialTool: 0)),
                ),
              ),
              BettboxChip(
                icon: Symbols.verified_rounded,
                label: MiliLocale.t('بازگشایی سرویس', 'Unlock'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MiliToolboxPage(initialTool: 1)),
                ),
              ),
              BettboxChip(
                icon: Symbols.public_rounded,
                label: MiliLocale.t('بررسی آی‌پی', 'IP Lookup'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MiliToolboxPage(initialTool: 2)),
                ),
              ),
              BettboxChip(
                icon: Symbols.network_ping_rounded,
                label: MiliLocale.t('پینگ محلی', 'Ping'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MiliToolboxPage(initialTool: 3)),
                ),
              ),
              BettboxChip(
                icon: Symbols.dns_rounded,
                label: MiliLocale.t('پرس‌وجوی DNS', 'DNS Query'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MiliToolboxPage(initialTool: 4)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 2: Bettbox-Style Nodes / Proxies Tab (Worker Deployments, Protocols,
// Built-in Cores, Chain Proxies & Panel Sync)
// ---------------------------------------------------------------------------

class _BettboxNodesTab extends StatefulWidget {
  const _BettboxNodesTab();

  @override
  State<_BettboxNodesTab> createState() => _BettboxNodesTabState();
}

class _BettboxNodesTabState extends State<_BettboxNodesTab> {
  final _subUrlCtrl = TextEditingController();
  final _client = MiliPanelClient();
  bool _syncing = false;
  String? _syncMsg;

  @override
  void dispose() {
    _subUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final deployments = state.deployments;
    final selectedDep = state.selected;
    final chains = state.profile.chains;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 102),
      children: [
        // 1. Cloudflare Worker & Pages Nodes
        BettboxTileCard(
          title: MiliLocale.t('نودهای ورکر کلادفلر', 'Cloudflare Worker Nodes'),
          icon: Symbols.cloud_rounded,
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CfAccountsPage()),
              ),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: const Icon(Symbols.add_rounded, size: 16),
              label: Text(MiliLocale.t('مدیریت', 'Manage')),
            ),
          ],
          child: deployments.isEmpty
              ? Text(
                  MiliLocale.t(
                    'هنوز ورکر کلادفلر نصب نشده است. از دکمه مدیریت برای استقرار استفاده کنید.',
                    'No Cloudflare worker deployed yet. Tap Manage to deploy.',
                  ),
                  style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.95,
                  ),
                  itemCount: deployments.length,
                  itemBuilder: (context, i) {
                    final item = deployments[i];
                    final isSelected = selectedDep != null &&
                        AppState.deploymentKey(selectedDep.account, selectedDep.deployment) ==
                            AppState.deploymentKey(item.account, item.deployment) &&
                        state.mode == ConnectionMode.worker;
                    final isPages = item.deployment.type == WorkerType.pages;
                    return _NodeCard(
                      title: isPages ? 'Pages Node' : 'Worker Node',
                      subtitle: item.deployment.customDomain ?? item.deployment.host,
                      badge: isPages ? 'PAGES' : 'WORKER',
                      selected: isSelected,
                      onTap: () {
                        state.selectDeployment(item.account, item.deployment);
                        state.setMode(ConnectionMode.worker);
                      },
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),

        // 2. Worker Protocol Selector Nodes (VLESS WS, VLESS XHTTP, Trojan WS, Shadowsocks WS)
        BettboxTileCard(
          title: MiliLocale.t(
            'پروتکل‌های نود ورکر',
            'Worker Protocol Nodes',
          ),
          icon: Symbols.hub_rounded,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: [
              for (final p in const [
                ('vless_ws', 'VLESS · WS', 'WebSocket + TLS'),
                ('vless_xhttp', 'VLESS · XHTTP', 'HTTP/2 Stream'),
                ('trojan_ws', 'Trojan · WS', 'SHA-224 + TLS'),
                ('shadowsocks_ws', 'Shadowsocks', 'SS + WS + TLS'),
              ])
                _NodeCard(
                  title: p.$2,
                  subtitle: p.$3,
                  badge: 'CORE',
                  selected: state.mode == ConnectionMode.worker &&
                      state.device.workerProtocol == p.$1,
                  onTap: () {
                    state.write('device.connection.workerProtocol', p.$1);
                    state.setMode(ConnectionMode.worker);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Built-in Direct Core Nodes (WARP, MASQUE, Serverless, Psiphon, Tor)
        BettboxTileCard(
          title: MiliLocale.t('نودهای داخلی بدون نیاز به ورکر', 'Built-in Core Nodes'),
          icon: Symbols.shield_rounded,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: [
              for (final m in const [
                (ConnectionMode.warp, 'WARP', 'WireGuard UDP'),
                (ConnectionMode.masque, 'MASQUE', 'HTTP/3 QUIC'),
                (ConnectionMode.serverless, 'Serverless', 'Direct Fragment'),
                (ConnectionMode.psiphon, 'Psiphon', 'Built-in Tunnel'),
                (ConnectionMode.tor, 'Tor', 'Onion Routing'),
              ])
                _NodeCard(
                  title: m.$2,
                  subtitle: m.$3,
                  badge: 'DIRECT',
                  selected: state.mode == m.$1,
                  onTap: () => state.setMode(m.$1),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4. Chain Proxy Nodes + Subscription Import
        BettboxTileCard(
          title: MiliLocale.t(
            'نودهای زنجیره‌ای و ساب‌لینک (${chains.length})',
            'Chain Nodes & Subscriptions (${chains.length})',
          ),
          icon: Symbols.link_rounded,
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChainProxiesPage()),
              ),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: const Icon(Symbols.add_rounded, size: 16),
              label: Text(MiliLocale.t('افزودن', 'Add')),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chains.isNotEmpty) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.1,
                  ),
                  itemCount: chains.length,
                  itemBuilder: (context, i) {
                    final c = chains[i];
                    final active = state.exitNode == ExitNode.chain &&
                        state.exitChain?.id == c.id;
                    return _NodeCard(
                      title: c.name,
                      subtitle: ChainInfo.of(c.link)?.protocol ?? 'Proxy',
                      badge: 'CHAIN',
                      selected: active,
                      onTap: () {
                        state.setExitChain(c);
                        state.setExitNode(ExitNode.chain);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subUrlCtrl,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: MiliLocale.t(
                          'لینک ساب‌لینک پنل میلی…',
                          'Paste Mili subscription URL…',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _syncing ? null : _importSub,
                    child: _syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(MiliLocale.t('ورود', 'Import')),
                  ),
                ],
              ),
              if (_syncMsg != null) ...[
                const SizedBox(height: 6),
                Text(_syncMsg!, style: TextStyle(fontSize: 12, color: scheme.primary)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _importSub() async {
    setState(() {
      _syncing = true;
      _syncMsg = null;
    });
    try {
      final links = await _client.fetchSubscriptionLinks(_subUrlCtrl.text);
      if (!mounted) return;
      if (links.isNotEmpty) {
        final chains = parseChainProxies(links.join('\n'));
        AppScope.read(context).addChains(chains);
        setState(() => _syncMsg = 'Imported ${chains.length} node(s).');
      } else {
        setState(() => _syncMsg = 'No supported proxy links found.');
      }
    } catch (e) {
      if (mounted) setState(() => _syncMsg = '$e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }
}

class _NodeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final bool selected;
  final VoidCallback onTap;

  const _NodeCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.4 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.22)
                          : scheme.surfaceContainer,
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: selected ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(Symbols.check_circle_rounded, size: 16, color: scheme.primary),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 3: Enhanced Dual-Engine Scanner + 696 Clean IP & ProxyIP Pool
// ---------------------------------------------------------------------------

class _MiliScannerTab extends StatefulWidget {
  const _MiliScannerTab();

  @override
  State<_MiliScannerTab> createState() => _MiliScannerTabState();
}

class _MiliScannerTabState extends State<_MiliScannerTab> {
  String _selectedCountry = '';
  String _query = '';
  late final Future<MiliIpPoolData> _poolFuture = MiliCatalog.loadIpPool();
  final _liveScanner = MiliLiveScanner();
  StreamSubscription? _scanSub;
  bool _scanning = false;
  int _tested = 0;
  int _total = 0;
  List<MiliScanResult> _liveResults = const [];

  @override
  void dispose() {
    _liveScanner.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  void _applyCleanIps(BuildContext context, List<String> ips, String label) {
    if (ips.isEmpty) return;
    AppScope.read(context).write('vless.cleanIps', ips);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          MiliLocale.t(
            '${ips.length} آی‌پی ($label) به‌عنوان آی‌پی تمیز ثبت شد',
            'Set ${ips.length} IP(s) ($label) as VLESS Clean IPs',
          ),
        ),
      ),
    );
  }

  void _applyProxyIps(BuildContext context, List<String> ips, String label) {
    if (ips.isEmpty) return;
    final formatted = ips
        .map((ip) => ip.contains(':') && !ip.startsWith('[') ? '[$ip]:443' : (ip.contains(':') ? ip : '$ip:443'))
        .toList();
    AppScope.read(context).write('vless.proxyIps', formatted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          MiliLocale.t(
            '${formatted.length} آی‌پی ($label) به‌عنوان پروکسی آی‌پی ثبت شد',
            'Set ${formatted.length} IP(s) ($label) as Worker ProxyIPs',
          ),
        ),
      ),
    );
  }

  void _startLiveScan(MiliIpPoolData data) {
    _liveScanner.cancel();
    _scanSub?.cancel();
    final pool = List<MiliIpEntry>.of(data.byCountry(_selectedCountry))..shuffle();
    final sample = pool.take(80).toList();
    setState(() {
      _scanning = true;
      _tested = 0;
      _total = sample.length;
      _liveResults = const [];
    });
    _scanSub = _liveScanner.scan(entries: sample).listen(
      (ev) {
        if (!mounted) return;
        setState(() {
          _tested = ev.tested;
          _total = ev.total;
          _liveResults = ev.results;
        });
      },
      onDone: () {
        if (mounted) setState(() => _scanning = false);
      },
      onError: (_) {
        if (mounted) setState(() => _scanning = false);
      },
    );
  }

  void _stopLiveScan() {
    _liveScanner.cancel();
    _scanSub?.cancel();
    setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentCleanIps = AppScope.of(context).vless.cleanIps;
    final currentProxyIps = AppScope.of(context).vless.proxyIps;

    return FutureBuilder<MiliIpPoolData>(
      future: _poolFuture,
      builder: (context, snap) {
        final data = snap.data;
        final filtered = data == null
            ? const <MiliIpEntry>[]
            : data.byCountry(_selectedCountry).where((e) {
                if (_query.isEmpty) return true;
                return e.ip.contains(_query) ||
                    e.country.toLowerCase().contains(_query.toLowerCase());
              }).toList();

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    // 1. Live Fast Mili TCP Scanner (works immediately, zero worker needed!)
                    BettboxTileCard(
                      title: MiliLocale.t(
                        'اسکنر زنده سریع (استخر ۶۹۶ آی‌پی میلی)',
                        'Live Fast Scanner (696 Mili Pool)',
                      ),
                      icon: Symbols.speed_rounded,
                      watermarkIcon: Symbols.radar_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: data == null
                                      ? null
                                      : (_scanning
                                            ? _stopLiveScan
                                            : () => _startLiveScan(data)),
                                  icon: Icon(
                                    _scanning
                                        ? Symbols.stop_rounded
                                        : Symbols.play_arrow_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _scanning
                                        ? MiliLocale.t('توقف اسکن', 'Stop Scan')
                                        : MiliLocale.t('شروع اسکن زنده', 'Start Live Scan'),
                                  ),
                                ),
                              ),
                              if (_liveResults.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                FilledButton.tonal(
                                  onPressed: () => _applyCleanIps(
                                    context,
                                    _liveResults.take(8).map((e) => e.ip).toList(),
                                    'Fastest ${_liveResults.take(8).length}',
                                  ),
                                  child: Text(MiliLocale.t('آی‌پی تمیز', 'Clean IP')),
                                ),
                                const SizedBox(width: 6),
                                FilledButton.tonal(
                                  onPressed: () => _applyProxyIps(
                                    context,
                                    _liveResults.take(5).map((e) => e.ip).toList(),
                                    'Fastest ${_liveResults.take(5).length}',
                                  ),
                                  child: Text(MiliLocale.t('پروکسی', 'ProxyIP')),
                                ),
                              ],
                            ],
                          ),
                          if (_scanning || _total > 0) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                value: _total == 0 ? 0 : _tested / _total,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              MiliLocale.t(
                                'بررسی‌شده: $_tested از $_total · سالم یافت‌شده: ${_liveResults.length}',
                                'Tested: $_tested / $_total · Alive: ${_liveResults.length}',
                              ),
                              style: _tabular.copyWith(
                                fontSize: 11.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (_liveResults.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            for (final r in _liveResults.take(6))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: scheme.surfaceContainerHigh,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(countryFlag(r.country)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          r.ip,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${r.pingMs} ms',
                                        style: _tabular.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: r.pingMs < 180
                                              ? _activeGreen
                                              : (r.pingMs < 400
                                                    ? const Color(0xFFFBBF24)
                                                    : scheme.error),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _applyCleanIps(context, [r.ip], r.country),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(Symbols.bolt_rounded, size: 17, color: scheme.primary),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _applyProxyIps(context, [r.ip], r.country),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(Symbols.dns_rounded, size: 17, color: scheme.secondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Native Go REAL Tunnel Scanners (VLESS, WARP, MASQUE H2/H3)
                    BettboxTileCard(
                      title: MiliLocale.t(
                        'اسکنر عمیق تونل کلادفلر (REAL Scanner)',
                        'Cloudflare REAL Tunnel Scanner',
                      ),
                      icon: Symbols.radar_rounded,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in const [
                            (ScanProtocol.vless, 'VLESS'),
                            (ScanProtocol.warp, 'WARP'),
                            (ScanProtocol.masqueH2, 'MASQUE H2'),
                            (ScanProtocol.masqueH3, 'MASQUE H3'),
                          ])
                            BettboxChip(
                              icon: Symbols.radar_rounded,
                              label: s.$2,
                              active: true,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CloudflareScannerPage(protocol: s.$1),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. 696 IP Pool Header (Dual Clean IP + ProxyIP actions)
                    BettboxTileCard(
                      title: MiliLocale.t(
                        'استخر ۶۹۶ آی‌پی (آی‌پی تمیز + پروکسی آی‌پی)',
                        '696 IP Pool (Clean IP + ProxyIP)',
                      ),
                      icon: Symbols.dns_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data != null)
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => _applyCleanIps(
                                      context,
                                      data.pickRandom(count: 10, countryCode: _selectedCountry),
                                      _selectedCountry.isEmpty ? 'Random' : _selectedCountry,
                                    ),
                                    icon: const Icon(Symbols.bolt_rounded, size: 16),
                                    label: Text(MiliLocale.t('۱۰ آی‌پی تمیز', '10 Clean IPs')),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => _applyProxyIps(
                                      context,
                                      data.pickRandom(count: 5, countryCode: _selectedCountry),
                                      _selectedCountry.isEmpty ? 'Random' : _selectedCountry,
                                    ),
                                    icon: const Icon(Symbols.dns_rounded, size: 16),
                                    label: Text(MiliLocale.t('۵ پروکسی آی‌پی', '5 ProxyIPs')),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(
                              isDense: true,
                              prefixIcon: const Icon(Symbols.search_rounded, size: 19),
                              hintText: MiliLocale.t(
                                'جستجوی آی‌پی یا کشور (DE, NL, US)…',
                                'Search IP or country (DE, NL, US)…',
                              ),
                            ),
                            onChanged: (v) => setState(() => _query = v.trim()),
                          ),
                          if (data != null) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 36,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(end: 8),
                                    child: ChoiceChip(
                                      selected: _selectedCountry.isEmpty,
                                      visualDensity: VisualDensity.compact,
                                      label: Text(
                                        '${MiliLocale.t("همه", "All")} (${data.ips.length})',
                                      ),
                                      onSelected: (_) =>
                                          setState(() => _selectedCountry = ''),
                                    ),
                                  ),
                                  for (final c in data.countries)
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(end: 8),
                                      child: ChoiceChip(
                                        selected: _selectedCountry == c.code,
                                        visualDensity: VisualDensity.compact,
                                        label: Text(
                                          '${countryFlag(c.code)} ${c.code} (${c.count})',
                                        ),
                                        onSelected: (_) =>
                                            setState(() => _selectedCountry = c.code),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (data == null)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 102),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    final isClean = currentCleanIps.contains(item.ip);
                    final isProxy = currentProxyIps.contains('${item.ip}:443');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 7),
                      shape: roundedShape(
                        15,
                        side: BorderSide(
                          color: (isClean || isProxy)
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Text(
                          countryFlag(item.country),
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          item.ip,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${item.country} · ${isClean ? "Clean IP " : ""}${isProxy ? "ProxyIP" : ""}'
                              .trim(),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: MiliLocale.t('ثبت به‌عنوان آی‌پی تمیز', 'Set as Clean IP'),
                              icon: Icon(
                                Symbols.bolt_rounded,
                                size: 19,
                                color: isClean ? _activeGreen : scheme.primary,
                              ),
                              onPressed: () =>
                                  _applyCleanIps(context, [item.ip], item.country),
                            ),
                            IconButton(
                              tooltip: MiliLocale.t('ثبت به‌عنوان پروکسی آی‌پی', 'Set as ProxyIP'),
                              icon: Icon(
                                Symbols.dns_rounded,
                                size: 19,
                                color: isProxy ? _activeGreen : scheme.secondary,
                              ),
                              onPressed: () =>
                                  _applyProxyIps(context, [item.ip], item.country),
                            ),
                            IconButton(
                              tooltip: MiliLocale.t('کپی', 'Copy'),
                              icon: const Icon(Symbols.content_copy_rounded, size: 17),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: item.ip));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied ${item.ip}')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
