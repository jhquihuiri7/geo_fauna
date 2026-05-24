import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/field_data_service.dart';
import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import '../widgets/live_map.dart';
import '../widgets/user_avatar.dart';

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
          EcoTopBar(
            title: 'EcoGuía Galápagos',
            leading: const UserAvatar(size: 40, status: AvatarStatus.on),
            trailing: const [
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
  final _dataService = FieldDataService();
  final _picker = ImagePicker();
  final _speciesController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  String _cat = 'Fauna';
  bool _publish = true;
  late DateTime _recordDate = DateTime.now();
  late TimeOfDay _recordTime = TimeOfDay.fromDateTime(DateTime.now());
  bool _saving = false;
  final List<EvidenceDraft> _evidence = [];

  static const _cats = [
    ['Fauna', '🐢'],
    ['Incidente', '⚠️'],
    ['Flora', '🌿'],
    ['Basura', '🗑️'],
  ];

  @override
  void dispose() {
    _speciesController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
                  Text(
                    'MÓDULO DE CAMPO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: eco.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nuevo Registro\nde Campo',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: -1.2,
                      color: eco.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Documenta tus hallazgos científicos o reporta incidentes en tiempo real.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: eco.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: eco.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month,
                color: eco.onSecondaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionLabel(eco, 'Ubicación del Registro'),
        const SizedBox(height: 8),
        LiveMap(
          height: 168,
          borderRadius: 28,
          zoom: 15,
          overlays: [
            Positioned(
              bottom: 12,
              left: 12,
              child: Glass(
                borderRadius: BorderRadius.circular(18),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location, size: 14, color: eco.primary),
                    const SizedBox(width: 6),
                    Text(
                      'UBICACIÓN ACTUAL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: eco.onSurface,
                      ),
                    ),
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
                    color: _cat == c[0] ? eco.primary : eco.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c[1], style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        c[0],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _cat == c[0] ? eco.onPrimary : eco.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _saving ? null : _pickEvidence,
          child: DottedBorderTile(
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: eco.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: _evidence.isEmpty
                      ? Icon(Icons.add_a_photo, color: eco.onSecondaryContainer)
                      : ClipOval(
                          child: _evidence.first.type == EvidenceType.image
                              ? Image.file(
                                  File(_evidence.first.file.path),
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.videocam,
                                  color: eco.onSecondaryContainer,
                                ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _evidence.isEmpty
                            ? 'Capturar Evidencia'
                            : '${_evidence.length} evidencia(s) lista(s)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: eco.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _evidence.isEmpty
                            ? 'Agrega foto o video del hallazgo'
                            : _evidence.map((e) => e.type.name).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: eco.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_evidence.isNotEmpty)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _saving
                        ? null
                        : () => setState(() => _evidence.clear()),
                    icon: Icon(Icons.close, color: eco.outline),
                  )
                else
                  Icon(Icons.expand_more, color: eco.outline),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _pillField(
          eco,
          cap: 'Fecha y Hora',
          onTap: () async {
            final date = await _pickDate(context, initialDate: _recordDate);
            if (date == null || !context.mounted) return;
            final time = await _pickTime(context, initialTime: _recordTime);
            if (time == null) return;
            setState(() {
              _recordDate = date;
              _recordTime = time;
            });
          },
          child: _pickerLine(
            eco,
            icon: Icons.event,
            text: '${_formatDate(_recordDate)} — ${_formatTime(_recordTime)}',
            helper: 'TOCA PARA CAMBIAR',
          ),
        ),
        const SizedBox(height: 16),
        _pillField(
          eco,
          cap: 'Especie (Opcional)',
          child: Row(
            children: [
              Icon(Icons.science, color: eco.outline),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _speciesController,
                  enabled: !_saving,
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
          ),
        ),
        const SizedBox(height: 16),
        _pillField(
          eco,
          cap: 'Cantidad de Individuos',
          child: Row(
            children: [
              Icon(Icons.groups, color: eco.outline),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 14, color: eco.onSurface),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            controller: _notesController,
            enabled: !_saving,
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
                    Text(
                      'Publicar en Muro',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: eco.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compartir este registro con la comunidad de guías',
                      style: TextStyle(
                        fontSize: 11,
                        color: eco.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              EcoSwitch(
                value: _publish,
                onChanged: (v) => setState(() => _publish = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(
          label: _saving ? 'Guardando...' : 'Subir Reporte',
          icon: Icons.upload,
          loading: _saving,
          onPressed: _saveRecord,
        ),
      ],
    );
  }

  Future<void> _pickEvidence() async {
    final choice = await _evidenceChoice(context);
    if (choice == null) return;

    XFile? file;
    if (choice == _EvidenceChoice.cameraPhoto) {
      file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      final selected = file;
      if (selected == null || !mounted) return;
      setState(() {
        _evidence.add(EvidenceDraft(file: selected, type: EvidenceType.image));
      });
      return;
    }

    if (choice == _EvidenceChoice.galleryPhoto) {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      final selected = file;
      if (selected == null || !mounted) return;
      setState(() {
        _evidence.add(EvidenceDraft(file: selected, type: EvidenceType.image));
      });
      return;
    }

    file = await _picker.pickVideo(source: ImageSource.gallery);
    final selected = file;
    if (selected == null || !mounted) return;
    setState(() {
      _evidence.add(EvidenceDraft(file: selected, type: EvidenceType.video));
    });
  }

  Future<void> _saveRecord() async {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showSnack(context, 'Ingresa una cantidad valida.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await _dataService.createFieldRecord(
        category: _cat,
        observedAt: _combineDateAndTime(_recordDate, _recordTime),
        quantity: quantity,
        publishToWall: _publish,
        evidence: List.of(_evidence),
        speciesName: _speciesController.text,
        notes: _notesController.text,
      );
      if (!mounted) return;
      setState(() {
        _speciesController.clear();
        _quantityController.text = '1';
        _notesController.clear();
        _evidence.clear();
        _recordDate = DateTime.now();
        _recordTime = TimeOfDay.fromDateTime(DateTime.now());
      });
      _showSnack(context, 'Reporte guardado correctamente.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, 'No se pudo guardar el reporte: $error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
  final _dataService = FieldDataService();
  final _nameController = TextEditingController();
  final _meetingPointController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'Terrestre';
  DateTime? _tourDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _saving = false;

  static const _types = [
    ['Marino', Icons.sailing],
    ['Terrestre', Icons.landscape],
    ['Avistamiento', Icons.visibility],
    ['Educativo', Icons.school],
    ['Tour diario', Icons.calendar_month],
    ['Crucero', Icons.directions_boat],
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _meetingPointController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        Text(
          'REGISTRO DE EXPEDICIÓN',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: eco.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Nuevo Registro',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -1.5,
            color: eco.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        _barTitle(eco, 'Información Básica'),
        const SizedBox(height: 16),
        _pillField(
          eco,
          cap: 'Nombre del Tour',
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  enabled: !_saving,
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
          ),
        ),
        const SizedBox(height: 12),
        _pillField(
          eco,
          cap: 'Fecha',
          onTap: () async {
            final date = await _pickDate(
              context,
              initialDate: _tourDate ?? DateTime.now(),
            );
            if (date != null) setState(() => _tourDate = date);
          },
          child: _pickerLine(
            eco,
            icon: Icons.calendar_today,
            text: _tourDate == null
                ? 'Selecciona una fecha'
                : _formatDate(_tourDate!),
            empty: _tourDate == null,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _pillField(
                eco,
                cap: 'Hora Inicio',
                onTap: () async {
                  final time = await _pickTime(
                    context,
                    initialTime: _startTime ?? TimeOfDay.now(),
                  );
                  if (time != null) setState(() => _startTime = time);
                },
                child: _pickerLine(
                  eco,
                  icon: Icons.schedule,
                  text: _startTime == null ? '--:--' : _formatTime(_startTime!),
                  empty: _startTime == null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _pillField(
                eco,
                cap: 'Hora Fin',
                onTap: () async {
                  final time = await _pickTime(
                    context,
                    initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
                  );
                  if (time != null) setState(() => _endTime = time);
                },
                child: _pickerLine(
                  eco,
                  icon: Icons.hourglass_empty,
                  text: _endTime == null ? '--:--' : _formatTime(_endTime!),
                  empty: _endTime == null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: _barTitle(eco, 'Tipo de Tour')),
            const SizedBox(width: 8),
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
                    horizontal: 8,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: eco.primary.withValues(
                            alpha: _type == t[0] ? 0.18 : 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          t[1] as IconData,
                          color: _type == t[0]
                              ? eco.primary
                              : eco.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t[0] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: eco.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _pillField(
          eco,
          cap: 'Punto de Encuentro',
          child: Row(
            children: [
              Icon(Icons.location_on, color: eco.outline),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _meetingPointController,
                  enabled: !_saving,
                  style: TextStyle(fontSize: 14, color: eco.onSurface),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Muelle, sendero o zona de salida',
                    hintStyle: TextStyle(color: eco.outline, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Cap('Notas del Tour'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: eco.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _notesController,
            enabled: !_saving,
            maxLines: 3,
            style: TextStyle(fontSize: 14, color: eco.onSurface),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'Detalle logistica, pasajeros u observaciones...',
              hintStyle: TextStyle(color: eco.outline, fontSize: 14),
            ),
          ),
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
                    Text(
                      'Impacto Ambiental',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Recuerda registrar cualquier avistamiento de especies invasoras.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: _saving ? 'Guardando...' : 'Confirmar Tour',
          icon: Icons.rocket_launch,
          loading: _saving,
          onPressed: _saveTour,
        ),
      ],
    );
  }

  Future<void> _saveTour() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack(context, 'Ingresa el nombre del tour.', error: true);
      return;
    }
    if (_tourDate == null || _startTime == null || _endTime == null) {
      _showSnack(
        context,
        'Selecciona fecha, hora de inicio y hora fin.',
        error: true,
      );
      return;
    }

    final startAt = _combineDateAndTime(_tourDate!, _startTime!);
    final endAt = _combineDateAndTime(_tourDate!, _endTime!);
    if (!endAt.isAfter(startAt)) {
      _showSnack(
        context,
        'La hora fin debe ser posterior al inicio.',
        error: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _dataService.createTour(
        name: name,
        type: _type,
        startAt: startAt,
        endAt: endAt,
        meetingPoint: _meetingPointController.text,
        notes: _notesController.text,
      );
      if (!mounted) return;
      setState(() {
        _nameController.clear();
        _meetingPointController.clear();
        _notesController.clear();
        _tourDate = null;
        _startTime = null;
        _endTime = null;
      });
      _showSnack(context, 'Tour guardado correctamente.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, 'No se pudo guardar el tour: $error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
  final _dataService = FieldDataService();
  final _titleController = TextEditingController();
  final _objectivesController = TextEditingController();
  final _meetingPointController = TextEditingController();

  String _type = 'Misión';
  bool _public = true;
  int _participants = 10;
  DateTime? _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _saving = false;

  static const _types = [
    ['Misión', Icons.science],
    ['Taller', Icons.groups],
    ['Limpieza', Icons.delete],
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _objectivesController.dispose();
    _meetingPointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        Text(
          'Crear Evento',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -1.5,
            color: eco.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Registre una nueva actividad para el equipo de campo.',
          style: TextStyle(fontSize: 14, color: eco.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        EcoCard(
          radius: 32,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardLabel(eco, 'Información Básica'),
              const SizedBox(height: 16),
              _roundedInput(
                eco,
                'Título del evento',
                controller: _titleController,
                enabled: !_saving,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: eco.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: eco.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Visibilidad Pública',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: eco.onSurface,
                        ),
                      ),
                    ),
                    EcoSwitch(
                      value: _public,
                      onChanged: (v) => setState(() => _public = v),
                    ),
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
                          onTap: () => setState(() => _type = t[0] as String),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _type == t[0]
                                  ? eco.primary.withValues(alpha: 0.10)
                                  : eco.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _type == t[0]
                                    ? eco.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  t[1] as IconData,
                                  color: _type == t[0]
                                      ? eco.primary
                                      : eco.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (t[0] as String).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                    color: _type == t[0]
                                        ? eco.primary
                                        : eco.onSurfaceVariant,
                                  ),
                                ),
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
        _sectionCard(
          eco,
          'Objetivos Técnicos',
          child: Container(
            decoration: BoxDecoration(
              color: eco.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _objectivesController,
              enabled: !_saving,
              maxLines: 4,
              style: TextStyle(fontSize: 14, color: eco.onSurface),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Describa el propósito y metas de la actividad…',
                hintStyle: TextStyle(color: eco.outline, fontSize: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          eco,
          'Ubicación del Encuentro',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: eco.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: eco.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _meetingPointController,
                    enabled: !_saving,
                    style: TextStyle(fontSize: 14, color: eco.onSurface),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Lugar de encuentro',
                      hintStyle: TextStyle(color: eco.outline, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          eco,
          'Fecha',
          child: _pickerSurface(
            eco,
            onTap: () async {
              final date = await _pickDate(
                context,
                initialDate: _eventDate ?? DateTime.now(),
              );
              if (date != null) setState(() => _eventDate = date);
            },
            child: _pickerLine(
              eco,
              icon: Icons.event,
              text: _eventDate == null
                  ? 'Selecciona una fecha'
                  : _formatDate(_eventDate!),
              empty: _eventDate == null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          eco,
          'Horario',
          child: Row(
            children: [
              Expanded(
                child: _timeBox(
                  eco,
                  label: 'Inicio',
                  value: _startTime,
                  onTap: () async {
                    final time = await _pickTime(
                      context,
                      initialTime: _startTime ?? TimeOfDay.now(),
                    );
                    if (time != null) setState(() => _startTime = time);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeBox(
                  eco,
                  label: 'Fin',
                  value: _endTime,
                  onTap: () async {
                    final time = await _pickTime(
                      context,
                      initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
                    );
                    if (time != null) setState(() => _endTime = time);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          eco,
          'Participantes / Guías Invitados',
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
                    shape: BoxShape.circle,
                  ),
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
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$_participants',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: eco.onSurface,
                    ),
                  ),
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
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: eco.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: _saving ? 'Guardando...' : 'Confirmar Evento',
          trailingIcon: Icons.rocket_launch,
          height: 60,
          loading: _saving,
          onPressed: _saveEvent,
        ),
      ],
    );
  }

  Future<void> _saveEvent() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnack(context, 'Ingresa el titulo del evento.', error: true);
      return;
    }
    if (_eventDate == null || _startTime == null || _endTime == null) {
      _showSnack(
        context,
        'Selecciona fecha, hora de inicio y hora fin.',
        error: true,
      );
      return;
    }

    final startAt = _combineDateAndTime(_eventDate!, _startTime!);
    final endAt = _combineDateAndTime(_eventDate!, _endTime!);
    if (!endAt.isAfter(startAt)) {
      _showSnack(
        context,
        'La hora fin debe ser posterior al inicio.',
        error: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _dataService.createEvent(
        title: title,
        type: _type,
        startAt: startAt,
        endAt: endAt,
        isPublic: _public,
        participantCount: _participants,
        objectives: _objectivesController.text,
        meetingPoint: _meetingPointController.text,
      );
      if (!mounted) return;
      setState(() {
        _titleController.clear();
        _objectivesController.clear();
        _meetingPointController.clear();
        _eventDate = null;
        _startTime = null;
        _endTime = null;
        _participants = 10;
        _public = true;
      });
      _showSnack(context, 'Evento guardado correctamente.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, 'No se pudo guardar el evento: $error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _timeBox(
    AppColors eco, {
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return _pickerSurface(
      eco,
      onTap: onTap,
      child: _pickerLine(
        eco,
        icon: Icons.schedule,
        text: value == null ? label : _formatTime(value),
        empty: value == null,
        compact: true,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

enum _EvidenceChoice { cameraPhoto, galleryPhoto, galleryVideo }

DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

void _showSnack(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  final eco = context.eco;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? eco.error : eco.primary,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<_EvidenceChoice?> _evidenceChoice(BuildContext context) {
  final eco = context.eco;
  return showModalBottomSheet<_EvidenceChoice>(
    context: context,
    backgroundColor: eco.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: eco.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              _evidenceOption(
                context,
                eco,
                icon: Icons.photo_camera,
                title: 'Tomar foto',
                subtitle: 'Usar la camara del dispositivo',
                value: _EvidenceChoice.cameraPhoto,
              ),
              _evidenceOption(
                context,
                eco,
                icon: Icons.photo_library,
                title: 'Elegir foto',
                subtitle: 'Subir imagen desde galeria',
                value: _EvidenceChoice.galleryPhoto,
              ),
              _evidenceOption(
                context,
                eco,
                icon: Icons.video_library,
                title: 'Elegir video',
                subtitle: 'Subir video desde galeria',
                value: _EvidenceChoice.galleryVideo,
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _evidenceOption(
  BuildContext context,
  AppColors eco, {
  required IconData icon,
  required String title,
  required String subtitle,
  required _EvidenceChoice value,
}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    leading: Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: eco.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: eco.primary),
    ),
    title: Text(
      title,
      style: TextStyle(fontWeight: FontWeight.w800, color: eco.onSurface),
    ),
    subtitle: Text(subtitle, style: TextStyle(color: eco.onSurfaceVariant)),
    onTap: () => Navigator.pop(context, value),
  );
}

Widget _sectionLabel(AppColors eco, String t) => Text(
  t.toUpperCase(),
  style: TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.8,
    color: eco.onSurfaceVariant,
  ),
);

Widget _cardLabel(AppColors eco, String t) => Text(
  t.toUpperCase(),
  style: TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.8,
    color: eco.onSurfaceVariant,
  ),
);

Widget _barTitle(AppColors eco, String t) => Container(
  padding: const EdgeInsets.only(left: 12),
  decoration: BoxDecoration(
    border: Border(left: BorderSide(color: eco.primary, width: 3)),
  ),
  child: Text(
    t,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: eco.onSurface,
    ),
  ),
);

Widget _pillField(
  AppColors eco, {
  required String cap,
  required Widget child,
  VoidCallback? onTap,
}) {
  return Builder(
    builder: (context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Cap(cap),
          const SizedBox(height: 8),
          _pickerSurface(eco, onTap: onTap, rounded: false, child: child),
        ],
      );
    },
  );
}

Widget _pickerSurface(
  AppColors eco, {
  required Widget child,
  VoidCallback? onTap,
  bool rounded = true,
}) {
  final surface = Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: BoxDecoration(
      color: eco.surfaceContainerLow,
      borderRadius: BorderRadius.circular(rounded ? 999 : 28),
      border: onTap == null
          ? null
          : Border.all(color: eco.primary.withValues(alpha: 0.14)),
    ),
    child: child,
  );

  if (onTap == null) return surface;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(rounded ? 999 : 28),
    child: surface,
  );
}

Widget _pickerLine(
  AppColors eco, {
  required IconData icon,
  required String text,
  String? helper,
  bool empty = false,
  bool compact = false,
}) {
  return Row(
    children: [
      Icon(icon, color: empty ? eco.outline : eco.primary, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: empty ? FontWeight.w600 : FontWeight.w800,
                color: empty ? eco.outline : eco.onSurface,
              ),
            ),
            if (helper != null) ...[
              const SizedBox(height: 2),
              Text(
                helper,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: eco.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      if (!compact) Icon(Icons.expand_more, color: eco.outline),
    ],
  );
}

Future<DateTime?> _pickDate(
  BuildContext context, {
  required DateTime initialDate,
}) {
  final eco = context.eco;
  final now = DateTime.now();
  final firstDate = DateTime(now.year - 2, 1, 1);
  final lastDate = DateTime(now.year + 5, 12, 31);
  final safeInitial = initialDate.isBefore(firstDate)
      ? firstDate
      : initialDate.isAfter(lastDate)
      ? lastDate
      : initialDate;

  return showDatePicker(
    context: context,
    initialDate: safeInitial,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: 'Seleccionar fecha',
    cancelText: 'Cancelar',
    confirmText: 'Listo',
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: eco.primary,
            onPrimary: eco.onPrimary,
            surface: eco.surfaceContainerLowest,
            onSurface: eco.onSurface,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: eco.surfaceContainerLowest,
            headerBackgroundColor: eco.primary,
            headerForegroundColor: eco.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

Future<TimeOfDay?> _pickTime(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  final eco = context.eco;
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: 'Seleccionar hora',
    cancelText: 'Cancelar',
    confirmText: 'Listo',
    initialEntryMode: TimePickerEntryMode.dial,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: eco.primary,
            onPrimary: eco.onPrimary,
            surface: eco.surfaceContainerLowest,
            onSurface: eco.onSurface,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: eco.surfaceContainerLowest,
            dialHandColor: eco.primary,
            dialBackgroundColor: eco.surfaceContainerLow,
            hourMinuteColor: eco.primary.withValues(alpha: 0.12),
            hourMinuteTextColor: eco.onSurface,
            dayPeriodColor: eco.primary.withValues(alpha: 0.12),
            dayPeriodTextColor: eco.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String _formatTime(TimeOfDay value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

Widget _sectionCard(AppColors eco, String label, {required Widget child}) {
  return EcoCard(
    radius: 32,
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_cardLabel(eco, label), const SizedBox(height: 12), child],
    ),
  );
}

Widget _roundedInput(
  AppColors eco,
  String hint, {
  TextEditingController? controller,
  bool enabled = true,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    decoration: BoxDecoration(
      color: eco.surfaceContainerLow,
      borderRadius: BorderRadius.circular(999),
    ),
    child: TextField(
      controller: controller,
      enabled: enabled,
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
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28)),
      );
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
