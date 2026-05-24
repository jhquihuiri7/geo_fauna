import 'package:flutter/material.dart';

import 'services/app_navigation_service.dart';
import 'theme/app_colors.dart';
import 'widgets/eco_widgets.dart';
import 'widgets/animations.dart';
import 'screens/dashboard_screen.dart';
import 'screens/agenda_screen.dart';
import 'screens/nuevo_hub_screen.dart';
import 'screens/muro_screen.dart';
import 'screens/perfil_screen.dart';

/// Main authenticated shell — 5-tab bottom navigation with a raised center
/// "Nuevo" FAB. Mirrors `BottomNav` in components.jsx.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  String? _wallHighlightSourceKey;

  // Tabs already built. Only the Dashboard (0) is built on login; the rest are
  // built lazily on first tap so we don't pay for 5 heavy screens in one frame.
  final Set<int> _visited = {0};

  @override
  void initState() {
    super.initState();
    AppNavigationService.wallPostTarget.addListener(_openWallPostTarget);
    final pending = AppNavigationService.wallPostTarget.value;
    if (pending != null) {
      _index = 3;
      _visited.add(3);
      _wallHighlightSourceKey = pending.sourceKey;
    }
  }

  @override
  void dispose() {
    AppNavigationService.wallPostTarget.removeListener(_openWallPostTarget);
    super.dispose();
  }

  void _openWallPostTarget() {
    final target = AppNavigationService.wallPostTarget.value;
    if (target == null || !mounted) return;
    setState(() {
      _index = 3;
      _visited.add(3);
      _wallHighlightSourceKey = target.sourceKey;
    });
  }

  // dashboard, agenda, nuevo, muro, perfil — builders, not instances, so a tab
  // costs nothing until it is visited.
  Widget _buildScreen(int i) {
    final Widget screen = switch (i) {
      0 => const DashboardScreen(),
      1 => const AgendaScreen(),
      2 => const NuevoHubScreen(),
      3 => MuroScreen(highlightSourceKey: _wallHighlightSourceKey),
      _ => const PerfilScreen(),
    };
    // Each tab fades + slides in the first time it is shown.
    return FadeInUp(offset: 16, child: screen);
  }

  void _onTap(int i) {
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Scaffold(
      backgroundColor: eco.surface,
      body: Stack(
        children: [
          Positioned.fill(
            // Keep screen content clear of the status bar / notch at the top.
            // Bottom is handled by the nav bar's own inset padding, so the
            // screens can scroll behind it.
            child: SafeArea(
              bottom: false,
              // Lazy IndexedStack: unvisited tabs render nothing (never built
              // or laid out); visited-but-inactive tabs stay alive offstage so
              // their scroll position and form state are preserved.
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (var i = 0; i < 5; i++)
                    if (_visited.contains(i))
                      Offstage(
                        offstage: _index != i,
                        child: TickerMode(
                          enabled: _index == i,
                          child: _buildScreen(i),
                        ),
                      ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNav(active: _index, onTap: _onTap),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.active, required this.onTap});

  final int active;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem('Inicio', Icons.dashboard),
    _NavItem('Agenda', Icons.event_note),
    _NavItem('Nuevo', Icons.add), // center FAB
    _NavItem('Muro', Icons.forum),
    _NavItem('Perfil', Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    // Space taken by the system navigation bar / gesture area, so the nav
    // items aren't hidden behind it.
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    // The raised center FAB is drawn as an overlay (Clip.none) so it isn't
    // clipped by the glass bar's rounded ClipRRect.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Glass(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: eco.primary.withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(8, 10, 8, 12 + bottomInset),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(child: _buildItem(context, eco, i)),
              ],
            ),
          ),
        ),
        Positioned(
          top: -22,
          left: 0,
          right: 0,
          child: Center(child: _centerFab(context, eco)),
        ),
      ],
    );
  }

  Widget _centerFab(BuildContext context, AppColors eco) {
    final active = this.active == 2;
    return PressableScale(
      onTap: () => onTap(2),
      pressedScale: 0.88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: active ? 1.08 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: eco.organicGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  // Luminous double glow so the FAB reads as the hero action.
                  BoxShadow(
                    color: eco.primary.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: -2,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: eco.primaryFixedDim.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'NUEVO',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: eco.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, AppColors eco, int i) {
    final item = _items[i];
    final isActive = active == i;

    if (i == 2) {
      // Slot reserved for the raised center FAB, which is drawn as an overlay
      // in build() so it can extend above the bar without being clipped.
      return const SizedBox.shrink();
    }

    final color = isActive ? eco.primary : eco.outline;
    return GestureDetector(
      onTap: () => onTap(i),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.18 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  item.icon,
                  key: ValueKey(isActive),
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: color,
              ),
              child: Text(item.label.toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }
}
