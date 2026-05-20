import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import '../widgets/painters.dart';

/// Nuevo — capture hub with three segmented sub-screens: Monitoreo (field
/// record), Agenda (tour), Evento (create event) — port of screens-forms.jsx.
class NuevoHubScreen extends StatefulWidget {
  const NuevoHubScreen({super.key, this.initialTab = 'Monitoreo'});

  final String initialTab;

  @override
  State<NuevoHubScreen> createState() => _NuevoHubScreenState();
}

class _NuevoHubScreenState extends State<NuevoHubScreen> {
  late String _tab = widget.initialTab;
  static const _tabs = ['Monitoreo', 'Agenda', 'Evento'];

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      color: eco.surface,
      child: Column(
        children: [
          const EcoTopBar(
            title: 'EcoGuía Galápagos',
            leading: Avatar(
                size: 40,
                tone: AvatarTone.forest,
                emoji: '🦫',
                status: AvatarStatus.on),
            trailing: [
              Avatar(size: 36, tone: AvatarTone.primary, emoji: '🐢'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: SegTabs(
              tabs: _tabs,
              active: _tab,
              onChange: (t) => setState(() => _tab = t),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              'Agenda' => const _TourRecord(),
              'Evento' => const _EventCreate(),
              _ => const _FieldRecord(),
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Monitoreo — field record
// ─────────────────────────────────────────────────────────────────────────────

class _FieldRecord extends StatefulWidget {
  const _FieldRecord();

  @override
  State<_FieldRecord> createState() => _FieldRecordState();
}

class _FieldRecordState extends State<_FieldRecord> {
  String _cat = 'Fauna';
  bool _publish = true;

  static const _cats = [
    ['Fauna', '🐢'],
    ['Incidente', '⚠️'],
    ['Flora', '🌿'],
    ['Basura', '🗑️'],
  ];

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MÓDULO DE CAMPO',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                          color: eco.primary)),
                  const SizedBox(height: 4),
                  Text('Nuevo Registro\nde Campo',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -1.2,
                          color: eco.onSurface)),
                  const SizedBox(height: 12),
                  Text(
                      'Documenta tus hallazgos científicos o reporta incidentes en tiempo real.',
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: eco.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: eco.secondaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.calendar_month,
                  color: eco.onSecondaryContainer),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionLabel(eco, 'Ubicación del Registro'),
        const SizedBox(height: 8),
        TopoMap(
          minHeight: 168,
          borderRadius: 28,
          children: [
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle),
                child: Icon(Icons.explore, color: eco.primary, size: 20),
              ),
            ),
            Center(
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: eco.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const Icon(Icons.location_on,
                    color: Colors.white, size: 16),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Glass(
                borderRadius: BorderRadius.circular(18),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UBICACIÓN ACTUAL',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: eco.onSurfaceVariant)),
                    Text('Canal de Itabaca',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: eco.onSurface)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionLabel(eco, 'Seleccionar Categoría'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3.0,
          children: [
            for (final c in _cats)
              GestureDetector(
                onTap: () => setState(() => _cat = c[0]),
                child: Container(
                  decoration: BoxDecoration(
                    color: _cat == c[0]
                        ? eco.primary
                        : eco.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c[1], style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(c[0],
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _cat == c[0]
                                  ? eco.onPrimary
                                  : eco.onSurface)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        DottedBorderTile(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: eco.secondaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.add_a_photo,
                    color: eco.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Capturar Evidencia',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: eco.onSurface)),
                  const SizedBox(height: 2),
                  Text('Toma una foto del hallazgo',
                      style: TextStyle(
                          fontSize: 12, color: eco.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _pillField(eco,
            cap: 'Fecha y Hora',
            child: Row(
              children: [
                Icon(Icons.event, color: eco.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('24/05/2024 — 09:45 AM',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: eco.onSurface)),
                    Text('TOCA PARA CAMBIAR',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: eco.onSurfaceVariant)),
                  ],
                ),
              ],
            )),
        const SizedBox(height: 16),
        _pillField(eco,
            cap: 'Especie (Opcional)',
            child: Row(
              children: [
                Icon(Icons.science, color: eco.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: TextStyle(fontSize: 14, color: eco.onSurface),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Ej: Chelonoidis nigra…',
                      hintStyle: TextStyle(color: eco.outline, fontSize: 14),
                    ),
                  ),
                ),
              ],
            )),
        const SizedBox(height: 16),
        _pillField(eco,
            cap: 'Cantidad de Individuos',
            child: Row(
              children: [
                Icon(Icons.groups, color: eco.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: '1'),
                    style: TextStyle(fontSize: 14, color: eco.onSurface),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            )),
        const SizedBox(height: 16),
        const Cap('Notas y Observaciones'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: eco.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16),
          child: TextField(
            maxLines: 3,
            style: TextStyle(fontSize: 14, color: eco.onSurface),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText:
                  'Describe el estado del espécimen o los detalles del incidente observado…',
              hintStyle: TextStyle(color: eco.outline, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: eco.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Publicar en Muro',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: eco.onSurface)),
                    const SizedBox(height: 2),
                    Text('Compartir este registro con la comunidad de guías',
                        style: TextStyle(
                            fontSize: 11, color: eco.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              EcoSwitch(
                  value: _publish,
                  onChanged: (v) => setState(() => _publish = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(
            label: 'Subir Reporte', icon: Icons.upload, onPressed: () {}),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Agenda — tour record
// ─────────────────────────────────────────────────────────────────────────────

class _TourRecord extends StatefulWidget {
  const _TourRecord();

  @override
  State<_TourRecord> createState() => _TourRecordState();
}

class _TourRecordState extends State<_TourRecord> {
  String _type = 'Terrestre';
  static const _types = [
    ['Marino', Icons.sailing],
    ['Terrestre', Icons.landscape],
    ['Avistamiento', Icons.visibility],
    ['Educativo', Icons.school],
    ['Tour diario', Icons.calendar_month],
    ['Crucero', Icons.directions_boat],
  ];

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        Text('REGISTRO DE EXPEDICIÓN',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: eco.primary)),
        const SizedBox(height: 4),
        Text('Nuevo Registro',
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -1.5,
                color: eco.onSurface)),
        const SizedBox(height: 24),
        _barTitle(eco, 'Información Básica'),
        const SizedBox(height: 16),
        _pillField(eco,
            cap: 'Nombre del Tour',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(fontSize: 14, color: eco.onSurface),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'e.g. Tour León Dormido AM',
                      hintStyle: TextStyle(color: eco.outline, fontSize: 14),
                    ),
                  ),
                ),
                Icon(Icons.edit_note, color: eco.outline, size: 20),
              ],
            )),
        const SizedBox(height: 12),
        _pillField(eco,
            cap: 'Fecha',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('mm/dd/yyyy',
                    style: TextStyle(fontSize: 14, color: eco.outline)),
                Icon(Icons.calendar_today, color: eco.outline),
              ],
            )),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _pillField(eco,
                  cap: 'Hora Inicio',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('--:-- --',
                          style:
                              TextStyle(fontSize: 14, color: eco.outline)),
                      Icon(Icons.schedule, color: eco.outline),
                    ],
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _pillField(eco,
                  cap: 'Hora Fin',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('--:-- --',
                          style:
                              TextStyle(fontSize: 14, color: eco.outline)),
                      Icon(Icons.hourglass_empty, color: eco.outline),
                    ],
                  )),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _barTitle(eco, 'Tipo de Tour'),
            const EcoChip('Selección Única', tone: ChipTone.emerald),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            for (final t in _types)
              GestureDetector(
                onTap: () => setState(() => _type = t[0] as String),
                child: EcoCard(
                  radius: 24,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: eco.primary.withValues(
                              alpha: _type == t[0] ? 0.18 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(t[1] as IconData,
                            color: _type == t[0]
                                ? eco.primary
                                : eco.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Text(t[0] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: eco.onSurface)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        GradientPanel(
          radius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: const [
              Icon(Icons.eco, color: Colors.white, size: 24),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Impacto Ambiental',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    SizedBox(height: 2),
                    Text(
                        'Recuerda registrar cualquier avistamiento de especies invasoras.',
                        style: TextStyle(
                            fontSize: 12, height: 1.4, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
            label: 'Confirmar Tour',
            icon: Icons.rocket_launch,
            onPressed: () {}),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Evento — create event
// ─────────────────────────────────────────────────────────────────────────────

class _EventCreate extends StatefulWidget {
  const _EventCreate();

  @override
  State<_EventCreate> createState() => _EventCreateState();
}

class _EventCreateState extends State<_EventCreate> {
  String _type = 'Misión';
  bool _public = true;
  int _participants = 10;
  static const _types = [
    ['Misión', Icons.science],
    ['Taller', Icons.groups],
    ['Limpieza', Icons.delete],
  ];

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        Text('Crear Evento',
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -1.5,
                color: eco.onSurface)),
        const SizedBox(height: 8),
        Text('Registre una nueva actividad para el equipo de campo.',
            style: TextStyle(fontSize: 14, color: eco.onSurfaceVariant)),
        const SizedBox(height: 24),
        EcoCard(
          radius: 32,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardLabel(eco, 'Información Básica'),
              const SizedBox(height: 16),
              _roundedInput(eco, 'Título del evento'),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: eco.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: eco.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Visibilidad Pública',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: eco.onSurface)),
                    ),
                    EcoSwitch(
                        value: _public,
                        onChanged: (v) => setState(() => _public = v)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final t in _types)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _type = t[0] as String),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 14),
                            decoration: BoxDecoration(
                              color: _type == t[0]
                                  ? eco.primary.withValues(alpha: 0.10)
                                  : eco.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: _type == t[0]
                                      ? eco.primary
                                      : Colors.transparent,
                                  width: 2),
                            ),
                            child: Column(
                              children: [
                                Icon(t[1] as IconData,
                                    color: _type == t[0]
                                        ? eco.primary
                                        : eco.onSurfaceVariant),
                                const SizedBox(height: 8),
                                Text((t[0] as String).toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                        color: _type == t[0]
                                            ? eco.primary
                                            : eco.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(eco, 'Objetivos Técnicos',
            child: Container(
              decoration: BoxDecoration(
                color: eco.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(16),
              child: TextField(
                maxLines: 4,
                style: TextStyle(fontSize: 14, color: eco.onSurface),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Describa el propósito y metas de la actividad…',
                  hintStyle: TextStyle(color: eco.outline, fontSize: 14),
                ),
              ),
            )),
        const SizedBox(height: 16),
        _sectionCard(eco, 'Ubicación del Encuentro',
            child: _rowField(eco, Icons.location_on,
                'Estación Científica Charles Darwin')),
        const SizedBox(height: 16),
        _sectionCard(eco, 'Fecha',
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: eco.surfaceContainerLow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: eco.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('mm/dd/yyyy',
                        style: TextStyle(fontSize: 14, color: eco.outline)),
                  ),
                  Icon(Icons.calendar_month, color: eco.outline),
                ],
              ),
            )),
        const SizedBox(height: 16),
        _sectionCard(eco, 'Horario',
            child: Row(
              children: [
                Expanded(child: _timeBox(eco)),
                const SizedBox(width: 12),
                Expanded(child: _timeBox(eco)),
              ],
            )),
        const SizedBox(height: 16),
        _sectionCard(eco, 'Participantes / Guías Invitados',
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    if (_participants > 0) _participants--;
                  }),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: eco.surfaceContainerLow,
                        shape: BoxShape.circle),
                    child: Icon(Icons.remove, color: eco.onSurface),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: eco.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999)),
                    child: Text('$_participants',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: eco.onSurface)),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _participants++),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: eco.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle),
                    child: Icon(Icons.add, color: eco.primary),
                  ),
                ),
              ],
            )),
        const SizedBox(height: 24),
        GradientButton(
            label: 'Confirmar Evento',
            trailingIcon: Icons.rocket_launch,
            height: 60,
            onPressed: () {}),
      ],
    );
  }

  Widget _timeBox(AppColors eco) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('--:-- --', style: TextStyle(fontSize: 14, color: eco.outline)),
          Icon(Icons.schedule, color: eco.outline, size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _sectionLabel(AppColors eco, String t) => Text(t.toUpperCase(),
    style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
        color: eco.onSurfaceVariant));

Widget _cardLabel(AppColors eco, String t) => Text(t.toUpperCase(),
    style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
        color: eco.onSurfaceVariant));

Widget _barTitle(AppColors eco, String t) => Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: eco.primary, width: 3)),
      ),
      child: Text(t,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: eco.onSurface)),
    );

Widget _pillField(AppColors eco, {required String cap, required Widget child}) {
  return Builder(builder: (context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Cap(cap),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: eco.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
          ),
          child: child,
        ),
      ],
    );
  });
}

Widget _sectionCard(AppColors eco, String label, {required Widget child}) {
  return EcoCard(
    radius: 32,
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardLabel(eco, label),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

Widget _roundedInput(AppColors eco, String hint) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    decoration: BoxDecoration(
      color: eco.surfaceContainerLow,
      borderRadius: BorderRadius.circular(999),
    ),
    child: TextField(
      style: TextStyle(fontSize: 14, color: eco.onSurface),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(color: eco.outline, fontSize: 14),
      ),
    ),
  );
}

Widget _rowField(AppColors eco, IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: eco.surfaceContainerLow,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: [
        Icon(icon, color: eco.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 14, color: eco.onSurface)),
        ),
      ],
    ),
  );
}

/// Dashed-border tile used for the "capture evidence" affordance.
class DottedBorderTile extends StatelessWidget {
  const DottedBorderTile({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return CustomPaint(
      painter: _DashedTilePainter(eco.outlineVariant),
      child: Container(
        decoration: BoxDecoration(
          color: eco.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class _DashedTilePainter extends CustomPainter {
  _DashedTilePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(28)));
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + 6), paint);
        dist += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedTilePainter old) => old.color != color;
}
