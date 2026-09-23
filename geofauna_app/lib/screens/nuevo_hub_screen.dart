import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../services/calendar_service.dart';
import '../services/field_data_service.dart';
import '../services/location_service.dart';
import '../services/map_tile_service.dart';
import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import '../widgets/live_map.dart';
import '../widgets/user_avatar.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/brand_logo.dart';

/// Nuevo — capture hub with three segmented sub-screens: Monitoreo (field
/// record), Agenda (tour), Evento (create event) — port of screens-forms.jsx.
class NuevoHubScreen extends StatefulWidget {
  const NuevoHubScreen({
    super.key,
    this.initialTab = 'Monitoreo',
    this.onSaved,
  });

  final String initialTab;
  final ValueChanged<String?>? onSaved;

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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space5,
              AppSpacing.space4,
              AppSpacing.space5,
              0,
            ),
            child: SegTabs(
              tabs: _tabs,
              active: _tab,
              onChange: (t) => setState(() => _tab = t),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              'Agenda' => _TourRecord(onSaved: widget.onSaved),
              'Evento' => _EventCreate(onSaved: widget.onSaved),
              _ => _FieldRecord(onSaved: widget.onSaved),
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
  const _FieldRecord({this.onSaved});

  final ValueChanged<String?>? onSaved;

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
  LatLng? _selectedLocation;

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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space6,
        AppSpacing.space6,
        AppSpacing.space6,
        120,
      ),
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
                    style: AppTextStyles.eyebrow.copyWith(color: eco.primary),
                  ),
                  const SizedBox(height: AppSpacing.space1),
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
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    'Documenta tus hallazgos científicos o reporta incidentes en tiempo real.',
                    style: AppTextStyles.body.copyWith(
                      color: eco.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space4),
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
        const SizedBox(height: AppSpacing.space6),
        _sectionLabel(eco, 'Ubicación del Registro'),
        const SizedBox(height: AppSpacing.space2),
        GestureDetector(
          onTap: _saving ? null : _openLocationPicker,
          child: LiveMap(
            height: 168,
            borderRadius: 28,
            zoom: 15,
            location: _selectedLocation,
            overlays: [
              Positioned(
                bottom: 12,
                left: 12,
                child: Glass(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3_5,
                    vertical: AppSpacing.space2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location, size: 14, color: eco.primary),
                      const SizedBox(width: 6),
                      Text(
                        _selectedLocation != null
                            ? 'UBICACIÓN EDITADA'
                            : 'UBICACIÓN ACTUAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: _selectedLocation != null
                              ? eco.tertiary
                              : eco.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space6),
        _sectionLabel(eco, 'Seleccionar Categoría'),
        const SizedBox(height: AppSpacing.space3),
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c[1], style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        c[0],
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: _cat == c[0] ? eco.onPrimary : eco.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space6),
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
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _evidence.isEmpty
                            ? 'Capturar Evidencia'
                            : '${_evidence.length} evidencia(s) lista(s)',
                        style: AppTextStyles.bodyStrong.copyWith(
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
        const SizedBox(height: AppSpacing.space6),
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
        const SizedBox(height: AppSpacing.space4),
        _pillField(
          eco,
          cap: 'Especie (Opcional)',
          child: Row(
            children: [
              Icon(Icons.science, color: eco.outline),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: TextField(
                  controller: _speciesController,
                  enabled: !_saving,
                  style: AppTextStyles.body.copyWith(color: eco.onSurface),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Ej: Chelonoidis nigra…',
                    hintStyle: AppTextStyles.body.copyWith(color: eco.outline),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        _pillField(
          eco,
          cap: 'Cantidad de Individuos',
          child: Row(
            children: [
              Icon(Icons.groups, color: eco.outline),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.body.copyWith(color: eco.onSurface),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        const Cap('Notas y Observaciones'),
        const SizedBox(height: AppSpacing.space2),
        Container(
          decoration: BoxDecoration(
            color: eco.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: TextField(
            controller: _notesController,
            enabled: !_saving,
            maxLines: 3,
            style: AppTextStyles.body.copyWith(color: eco.onSurface),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText:
                  'Describe el estado del espécimen o los detalles del incidente observado…',
              hintStyle: AppTextStyles.body.copyWith(color: eco.outline),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4_5,
            vertical: AppSpacing.space3_5,
          ),
          decoration: BoxDecoration(
            color: eco.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Publicar en Muro',
                      style: AppTextStyles.bodyStrong.copyWith(
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
              const SizedBox(width: AppSpacing.space3),
              EcoSwitch(
                value: _publish,
                onChanged: (v) => setState(() => _publish = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        GradientButton(
          label: _saving ? 'Guardando...' : 'Subir Reporte',
          icon: Icons.upload,
          loading: _saving,
          onPressed: _saveRecord,
        ),
      ],
    );
  }

  Future<void> _openLocationPicker() async {
    final location = await LocationService().getCurrentLocation();
    final selectedLoc =
        _selectedLocation ?? LatLng(location.latitude, location.longitude);

    if (!mounted) return;

    final result = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.eco.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) => _LocationPickerSheet(
        initialLocation: selectedLoc,
        currentLocation: LatLng(location.latitude, location.longitude),
      ),
    );

    if (result != null && mounted) {
      setState(() => _selectedLocation = result);
    }
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
      final publishToWall = _publish;
      final recordId = await _dataService.createFieldRecord(
        category: _cat,
        observedAt: _combineDateAndTime(_recordDate, _recordTime),
        quantity: quantity,
        publishToWall: publishToWall,
        evidence: List.of(_evidence),
        speciesName: _speciesController.text,
        notes: _notesController.text,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _speciesController.clear();
        _quantityController.text = '1';
        _notesController.clear();
        _evidence.clear();
        _cat = 'Fauna';
        _publish = true;
        _recordDate = DateTime.now();
        _recordTime = TimeOfDay.fromDateTime(DateTime.now());
        _selectedLocation = null;
      });
      _showSnack(context, 'Reporte guardado correctamente.');
      widget.onSaved?.call(publishToWall ? 'fieldRecords/$recordId' : null);
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
  const _TourRecord({this.onSaved});

  final ValueChanged<String?>? onSaved;

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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space6,
        AppSpacing.space6,
        AppSpacing.space6,
        120,
      ),
      children: [
        Text(
          'REGISTRO DE EXPEDICIÓN',
          style: AppTextStyles.eyebrow.copyWith(color: eco.primary),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          'Nuevo Registro',
          style: AppTextStyles.display.copyWith(color: eco.onSurface),
        ),
        const SizedBox(height: AppSpacing.space6),
        _barTitle(eco, 'Información Básica'),
        const SizedBox(height: AppSpacing.space4),
        _pillField(
          eco,
          cap: 'Nombre del Tour',
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  enabled: !_saving,
                  style: AppTextStyles.body.copyWith(color: eco.onSurface),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'e.g. Tour León Dormido AM',
                    hintStyle: AppTextStyles.body.copyWith(color: eco.outline),
                  ),
                ),
              ),
              Icon(Icons.edit_note, color: eco.outline, size: 20),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
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
        const SizedBox(height: AppSpacing.space3),
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
            const SizedBox(width: AppSpacing.space3),
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
        const SizedBox(height: AppSpacing.space6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: _barTitle(eco, 'Tipo de Tour')),
            const SizedBox(width: AppSpacing.space2),
            const EcoChip('Selección Única', tone: ChipTone.emerald),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
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
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space4,
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
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        t[0] as String,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label.copyWith(
                          color: eco.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space6),
        _pillField(
          eco,
          cap: 'Punto de Encuentro',
          child: Row(
            children: [
              Icon(Icons.location_on, color: eco.outline),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: TextField(
                  controller: _meetingPointController,
                  enabled: !_saving,
                  style: AppTextStyles.body.copyWith(color: eco.onSurface),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Muelle, sendero o zona de salida',
                    hintStyle: AppTextStyles.body.copyWith(color: eco.outline),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        const Cap('Notas del Tour'),
        const SizedBox(height: AppSpacing.space2),
        Container(
          decoration: BoxDecoration(
            color: eco.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: TextField(
            controller: _notesController,
            enabled: !_saving,
            maxLines: 3,
            style: AppTextStyles.body.copyWith(color: eco.onSurface),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'Detalle logistica, pasajeros u observaciones...',
              hintStyle: AppTextStyles.body.copyWith(color: eco.outline),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space6),
        GradientPanel(
          radius: 28,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space5,
            vertical: AppSpacing.space4,
          ),
          child: Row(
            children: [
              // La marca sobre el degradado. 32px es el minimo del sistema:
              // por debajo las tres curvas del caparazon se empastan.
              const TortugaTopoMark.onFill(size: 32),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Impacto Ambiental',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
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
        const SizedBox(height: AppSpacing.space6),
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
        _type = 'Terrestre';
        _tourDate = null;
        _startTime = null;
        _endTime = null;
      });
      _showSnack(context, 'Tour guardado correctamente.');
      widget.onSaved?.call(null);
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
  const _EventCreate({this.onSaved});

  final ValueChanged<String?>? onSaved;

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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space6,
        AppSpacing.space6,
        AppSpacing.space6,
        120,
      ),
      children: [
        Text(
          'Crear Evento',
          style: AppTextStyles.display.copyWith(color: eco.onSurface),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'Registre una nueva actividad para el equipo de campo.',
          style: AppTextStyles.body.copyWith(color: eco.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.space6),
        EcoCard(
          radius: 32,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardLabel(eco, 'Información Básica'),
              const SizedBox(height: AppSpacing.space4),
              _roundedInput(
                eco,
                'Título del evento',
                controller: _titleController,
                enabled: !_saving,
              ),
              const SizedBox(height: AppSpacing.space3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4_5,
                  vertical: AppSpacing.space3,
                ),
                decoration: BoxDecoration(
                  color: eco.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: eco.primary),
                    const SizedBox(width: AppSpacing.space2),
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
              const SizedBox(height: AppSpacing.space4),
              Row(
                children: [
                  for (final t in _types)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space1,
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => _type = t[0] as String),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: AppSpacing.space3_5,
                            ),
                            decoration: BoxDecoration(
                              color: _type == t[0]
                                  ? eco.primary.withValues(alpha: 0.10)
                                  : eco.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
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
                                const SizedBox(height: AppSpacing.space2),
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
        const SizedBox(height: AppSpacing.space4),
        _sectionCard(
          eco,
          'Objetivos Técnicos',
          child: Container(
            decoration: BoxDecoration(
              color: eco.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: TextField(
              controller: _objectivesController,
              enabled: !_saving,
              maxLines: 4,
              style: AppTextStyles.body.copyWith(color: eco.onSurface),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Describa el propósito y metas de la actividad…',
                hintStyle: AppTextStyles.body.copyWith(color: eco.outline),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        _sectionCard(
          eco,
          'Ubicación del Encuentro',
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4_5,
              vertical: AppSpacing.space3_5,
            ),
            decoration: BoxDecoration(
              color: eco.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: eco.outline),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: TextField(
                    controller: _meetingPointController,
                    enabled: !_saving,
                    style: AppTextStyles.body.copyWith(color: eco.onSurface),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Lugar de encuentro',
                      hintStyle: AppTextStyles.body.copyWith(
                        color: eco.outline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
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
        const SizedBox(height: AppSpacing.space4),
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
              const SizedBox(width: AppSpacing.space3),
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
        const SizedBox(height: AppSpacing.space4),
        _sectionCard(
          eco,
          'Cupo máximo (0 = sin límite)',
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: eco.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
        const SizedBox(height: AppSpacing.space6),
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
      // El organizador queda auto-inscrito, así que agendamos el evento en su
      // calendario al publicar (best-effort: no bloquea si no hay permiso).
      final calendarEventId = await CalendarService.instance.addEvent(
        title: title,
        start: startAt,
        end: endAt,
        description: _objectivesController.text.trim().isEmpty
            ? null
            : _objectivesController.text.trim(),
        location: _meetingPointController.text.trim().isEmpty
            ? null
            : _meetingPointController.text.trim(),
      );
      await _dataService.createEvent(
        title: title,
        type: _type,
        startAt: startAt,
        endAt: endAt,
        isPublic: _public,
        capacity: _participants,
        objectives: _objectivesController.text,
        meetingPoint: _meetingPointController.text,
        ownerCalendarEventId: calendarEventId,
      );
      if (!mounted) return;
      setState(() {
        _titleController.clear();
        _objectivesController.clear();
        _meetingPointController.clear();
        _eventDate = null;
        _startTime = null;
        _endTime = null;
        _type = 'MisiÃ³n';
        _participants = 10;
        _public = true;
      });
      _showSnack(context, 'Evento guardado correctamente.');
      widget.onSaved?.call(null);
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
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space5,
            AppSpacing.space3,
            AppSpacing.space5,
            AppSpacing.space5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: eco.outlineVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
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

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({
    required this.initialLocation,
    required this.currentLocation,
  });

  final LatLng initialLocation;
  final LatLng currentLocation;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late LatLng _selectedPoint = widget.initialLocation;
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space5,
              AppSpacing.space3,
              AppSpacing.space5,
              AppSpacing.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: eco.outlineVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cambiar Ubicación',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: eco.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            'Haz tap en el mapa para seleccionar ubicación',
                            style: AppTextStyles.bodySm.copyWith(
                              color: eco.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 40),
                      ),
                      child: Icon(Icons.close, color: eco.outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedPoint,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onTap: (tapPosition, point) {
                    setState(() => _selectedPoint = point);
                  },
                ),
                children: [
                  MapTileService.baseTileLayer(),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPoint,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: eco.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: eco.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space5,
              AppSpacing.space4,
              AppSpacing.space5,
              AppSpacing.space5,
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () =>
                      setState(() => _selectedPoint = widget.currentLocation),
                  child: Text(
                    'Ubicación Actual',
                    style: TextStyle(color: eco.primary),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: TextStyle(color: eco.outline)),
                ),
                const SizedBox(width: AppSpacing.space2),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _selectedPoint),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.space1,
      vertical: AppSpacing.space1,
    ),
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
  style: AppTextStyles.eyebrow.copyWith(color: eco.onSurfaceVariant),
);

Widget _cardLabel(AppColors eco, String t) => Text(
  t.toUpperCase(),
  style: AppTextStyles.eyebrow.copyWith(color: eco.onSurfaceVariant),
);

Widget _barTitle(AppColors eco, String t) => Container(
  padding: const EdgeInsets.only(left: AppSpacing.space3),
  decoration: BoxDecoration(
    border: Border(left: BorderSide(color: eco.primary, width: 3)),
  ),
  child: Text(t, style: AppTextStyles.titleSm.copyWith(color: eco.onSurface)),
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
          const SizedBox(height: AppSpacing.space2),
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
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.space4_5,
      vertical: AppSpacing.space3,
    ),
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
      const SizedBox(width: AppSpacing.space3),
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
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
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
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
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
      children: [
        _cardLabel(eco, label),
        const SizedBox(height: AppSpacing.space3),
        child,
      ],
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
    padding: const EdgeInsets.symmetric(
      horizontal: 22,
      vertical: AppSpacing.space3_5,
    ),
    decoration: BoxDecoration(
      color: eco.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
    ),
    child: TextField(
      controller: controller,
      enabled: enabled,
      style: AppTextStyles.body.copyWith(color: eco.onSurface),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: eco.outline),
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
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        padding: const EdgeInsets.all(AppSpacing.space5),
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
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppSpacing.radiusXl),
        ),
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
