import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'widgets/eco_widgets.dart';
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

  // dashboard, agenda, nuevo, muro, perfil
  final _screens = const [
    DashboardScreen(),
    AgendaScreen(),
    NuevoHubScreen(),
    MuroScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Scaffold(
      backgroundColor: eco.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _index, children: _screens),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNav(
              active: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, {this.badge});
  final String label;
  final IconData icon;
  final int? badge;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.active, required this.onTap});

  final int active;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem('Inicio', Icons.dashboard),
    _NavItem('Agenda', Icons.event_note),
    _NavItem('Nuevo', Icons.add), // center FAB
    _NavItem('Muro', Icons.forum, badge: 3),
    _NavItem('Perfil', Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Glass(
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
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(child: _buildItem(context, eco, i)),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, AppColors eco, int i) {
    final item = _items[i];
    final isActive = active == i;

    if (i == 2) {
      // Raised center FAB
      return GestureDetector(
        onTap: () => onTap(2),
        behavior: HitTestBehavior.opaque,
        child: Transform.translate(
          offset: const Offset(0, -28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: eco.organicGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: eco.primary.withValues(alpha: 0.25),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 4),
              Text(item.label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: eco.primary)),
            ],
          ),
        ),
      );
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(item.icon, color: color, size: 24),
                if (item.badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                        border: Border.all(color: eco.surface, width: 2),
                      ),
                      child: Text('${item.badge}',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.label.toUpperCase(),
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
