# Plan Profesional de Backend GCP para GeoFauna

Fecha: 2026-05-23  
App analizada: `geofauna_app`  
Proyecto Firebase detectado: `geofaunagps`  
Android package detectado: `com.geofauna.app`

## 1. Lectura Tecnica de la App Actual

### Stack actual

- Flutter/Dart con Material UI personalizada.
- Firebase inicializado en `lib/main.dart`.
- Dependencias ya instaladas: `firebase_core`, `firebase_auth`,
  `cloud_firestore`, `firebase_storage`, `google_sign_in`, `image_picker`.
- Servicios actuales:
  - `AuthService`: login email/password, Google Sign-In, creacion de usuario,
    perfil en `users/{uid}`, foto de perfil en Storage.
  - `LocationService`: GPS + reverse geocoding.
  - `WeatherService`: Open-Meteo directo desde el cliente.
- Navegacion principal: `Dashboard`, `Agenda`, `Nuevo`, `Muro`, `Perfil`.

### Lo que ya esta conectado a datos reales

- Auth con Firebase.
- Documento `users/{uid}` para completar perfil.
- Avatar y pantalla de perfil leen parcialmente Firestore/Auth.
- Storage preparado para foto de perfil.
- Ubicacion y clima se resuelven en vivo desde el dispositivo.

### Lo que todavia esta en modo demo o estado vacio

- `NuevoHubScreen` tiene tres formularios con botones sin persistencia:
  - Registro de campo: categoria, foto, fecha/hora, especie, cantidad, notas,
    publicar en muro.
  - Tour/agenda: nombre, fecha, hora inicio/fin, tipo de tour.
  - Evento: titulo, visibilidad, tipo, objetivos, ubicacion, fecha, horario,
    participantes.
- `AgendaScreen` muestra estado vacio.
- `MuroScreen` usa eventos y avistamientos hardcodeados.
- `DashboardScreen` usa rankings, KPIs y especies hardcodeadas.
- `ReporteScreen` usa analitica hardcodeada.
- `PerfilScreen` muestra stats en cero y muro personal vacio.
- `SettingsScreen` muestra un usuario hardcodeado, no el perfil real.

### Riesgos tecnicos detectados antes de backend

- Formularios de `NuevoHubScreen` no conservan controladores como estado para
  todos los inputs; por ejemplo, un `TextEditingController(text: '1')` creado
  dentro de `build` puede resetear datos y generar fugas.
- `SignupScreen` muestra `ID Guardaparque`, `Tipo de Usuario` y `Especialidad`,
  pero el registro actual solo guarda nombre/email; el perfil se completa luego.
- Las pantallas mezclan datos reales y demo. Hay que aislar repositorios de
  datos antes de conectar todo.
- Para "todo Google", el mapa actual usa OpenStreetMap y el clima Open-Meteo.
  Se puede migrar mapas/geocoding a Google Maps Platform; clima debe definirse:
  API externa cacheada en Cloud Functions o servicio Google disponible en el
  proyecto si aplica.

## 2. Objetivo Backend

Construir un backend serverless, escalable y auditable que permita:

1. Guardar registros de campo, tours y eventos desde formularios Flutter.
2. Alimentar automaticamente Agenda, Muro, Perfil, Dashboard y Reporte.
3. Proteger datos sensibles de biodiversidad y ubicaciones.
4. Validar calidad cientifica: GPS, evidencia, duplicados, consistencia temporal
   y revision colaborativa.
5. Proveer roles: guia, guardaparque, investigador, moderador y administrador.
6. Mantener costos controlados con agregados y streams acotados.

## 3. Arquitectura Propuesta

### Servicios Google/Firebase

- Firebase Auth: identidad, Google Sign-In y custom claims de rol.
- Cloud Firestore: base operacional en tiempo real.
- Cloud Storage for Firebase: fotos de perfil y evidencia.
- Cloud Functions for Firebase v2 en Python: validaciones, escrituras
  transaccionales, triggers, notificaciones y jobs.
- Firebase App Check: proteccion contra clientes no autorizados.
- Firebase Cloud Messaging: alertas de eventos, comentarios, validaciones y
  clima/incidentes.
- Cloud Scheduler: recomputos diarios, cierre de eventos, resumen de rankings.
- Cloud Tasks o Pub/Sub: tareas diferidas si crece el procesamiento de imagen,
  notificaciones o analitica.
- Secret Manager: claves externas si se usa API de clima externa.
- Cloud Logging, Error Reporting, Crashlytics, Performance Monitoring.
- BigQuery export: analitica historica, dashboards y reportes avanzados.

### Patron recomendado

- Flutter llama Cloud Functions callable para escrituras sensibles.
- Firestore entrega streams/listas para lecturas en UI.
- Functions escriben documentos canonicos, resumenes publicos y agregados.
- Reglas de Firestore bloquean escrituras directas a colecciones criticas.
- Storage permite subida controlada por ruta/metadata y Functions procesan la
  evidencia.

### Region

- Usar la misma region logica de Firestore y Functions para reducir latencia.
- Si el proyecto actual ya esta creado, confirmar la ubicacion de Firestore
  antes del despliegue.
- Para MVP, `us-central1` suele ser la opcion con mejor compatibilidad Firebase.
  Si se crea un entorno nuevo, medir latencia desde Ecuador/Galapagos y revisar
  disponibilidad de todos los servicios antes de elegir otra region.

## 4. Modelo de Datos Firestore

### `users/{uid}`

Documento privado/controlado de perfil.

Campos:

- `uid`, `email`, `name`, `photoUrl`
- `rangerId`, `userType`, `specialty`
- `role`: `guide | ranger | researcher | moderator | admin`
- `status`: `pending | active | suspended`
- `profileCompleted`
- `zoneIds`: zonas asignadas
- `notificationPrefs`: alertas de campo, muro, eventos
- `createdAt`, `updatedAt`, `lastActiveAt`

Subcolecciones:

- `fcmTokens/{tokenId}`: token, platform, appVersion, updatedAt.
- `privateAudit/{auditId}`: cambios sensibles del perfil.

### `fieldRecords/{recordId}`

Registro canonico de avistamiento, flora, incidente o basura.

Campos:

- `recordId`
- `authorId`
- `authorSnapshot`: nombre, foto, rol, especialidad
- `category`: `fauna | flora | incident | trash`
- `speciesName`, `speciesId`, `speciesConfidence`
- `count`
- `notes`
- `observedAt`, `createdAt`, `updatedAt`
- `location`: GeoPoint exacto
- `geohash`, `zoneId`, `placeName`
- `accuracyMeters`
- `evidence`: lista de objetos `{storagePath, downloadUrl, thumbUrl, type}`
- `publishToWall`
- `visibility`: `private | team | public`
- `sensitive`: booleano calculado por especie/zona
- `publicLocation`: GeoPoint redondeado o centro de zona
- `status`: `submitted | needs_review | verified | rejected`
- `integrityScore`: 0-100
- `validationSummary`: confirmaciones, alertas, duplicados, comentarios

Subcolecciones:

- `comments/{commentId}`
- `reactions/{uid}`
- `validations/{uid}`
- `audit/{auditId}`

### `publicFeed/{recordId}`

Resumen seguro para Muro. No debe contener ubicacion exacta si `sensitive=true`.

Campos:

- `sourceRecordId`, `authorSnapshot`, `category`, `speciesName`
- `bodyPreview`, `photoThumbUrl`, `photoLabel`
- `publicLocation`, `placeLabel`, `createdAt`
- `integrityLabel`, `rankLabel`
- `reactionCounts`, `commentCount`

### `tours/{tourId}`

Registro de expedicion/tour.

Campos:

- `tourId`, `createdBy`, `assignedGuideIds`
- `name`
- `type`: `marine | terrestrial | sighting | educational | day_tour | cruise`
- `date`, `startAt`, `endAt`
- `zoneIds`, `meetingPoint`
- `status`: `scheduled | active | completed | cancelled`
- `createdAt`, `updatedAt`

### `events/{eventId}`

Eventos comunitarios o institucionales.

Campos:

- `eventId`, `createdBy`
- `title`, `type`: `mission | workshop | cleanup`
- `objectives`
- `visibility`: `private | team | public`
- `locationLabel`, `location`, `zoneId`
- `date`, `startAt`, `endAt`
- `capacity`, `participantCount`
- `status`: `draft | published | completed | cancelled`
- `xpReward`
- `createdAt`, `updatedAt`

Subcolecciones:

- `participants/{uid}`: role, joinedAt, status.
- `comments/{commentId}`.

### Agregados

- `userStats/{uid}`: avistamientos, especies, precision, horas, km, xp, badges.
- `dailyAgendas/{uid_yyyyMMdd}`: eventos/tours/recordatorios del dia.
- `globalStats/current`: KPIs para Dashboard.
- `monthlyReports/{yyyyMM}`: Reporte detallado.
- `leaderboards/{period}/entries/{uid}`.
- `speciesStats/{speciesId}`.
- `zoneStats/{zoneId}`.

### Catalogos

- `speciesCatalog/{speciesId}`: nombre cientifico, nombre comun, categoria,
  nivel sensible, estado de conservacion, aliases.
- `zones/{zoneId}`: nombre, isla, poligono simplificado, reglas de acceso.
- `badges/{badgeId}`.
- `systemConfig/{key}`.

## 5. Cloud Functions Python

### Funciones callable para Flutter

- `create_field_record`
  - Valida auth, App Check, perfil completo y cuota.
  - Normaliza categoria, especie, cantidad, notas, fecha y ubicacion.
  - Calcula zona/geohash, sensibilidad y estado inicial.
  - Crea `fieldRecords/{id}` y opcionalmente `publicFeed/{id}`.

- `create_tour`
  - Valida campos de agenda y solapamiento basico.
  - Crea `tours/{id}`.
  - Actualiza agenda del creador y guias asignados.

- `create_event`
  - Valida capacidad, visibilidad, horario y tipo.
  - Crea `events/{id}` publicado o privado.
  - Agenda notificaciones segun visibilidad.

- `join_event`
  - Agrega participante con transaccion.
  - Evita sobrepasar capacidad.

- `react_to_record`, `comment_record`, `validate_record`
  - Controlan interacciones del Muro.
  - Actualizan contadores y score de integridad.

- `update_profile`
  - Evita que el cliente edite rol/status directamente.
  - Guarda perfil y preferencias.

- `register_fcm_token`
  - Guarda token por usuario/dispositivo.

### Triggers Firestore

- `on_field_record_created`
  - Calcula integridad inicial.
  - Actualiza `userStats`, `speciesStats`, `zoneStats`, `globalStats`.
  - Crea entrada de feed si corresponde.

- `on_field_record_updated`
  - Recalcula agregados si cambia status, visibilidad o validacion.

- `on_event_created`
  - Notifica a usuarios elegibles.
  - Actualiza carrusel de eventos proximos.

- `on_tour_created`
  - Materializa agenda por dia.

- `on_user_created_or_profile_completed`
  - Inicializa stats, prefs y claims base si corresponde.

### Jobs programados

- `rebuild_daily_agendas`: cada madrugada.
- `rebuild_leaderboards`: cada hora o cada noche segun costo.
- `close_past_events`: cada hora.
- `generate_monthly_report`: primer dia de cada mes.
- `cleanup_orphan_storage`: diario.

## 6. Seguridad y Reglas

### Principios

- No confiar en campos enviados por el cliente para `authorId`, timestamps,
  rol, score, status o stats.
- Firestore rules autorizan lectura; las escrituras criticas pasan por Functions.
- Storage restringe rutas por usuario y tipo de archivo.
- Server Admin SDK bypassa reglas; por eso Functions deben validar IAM, auth y
  payload con disciplina.
- App Check debe activarse antes de produccion.

### Roles

- `guide`: crear registros, tours propios, ver feed publico/equipo.
- `ranger`: todo guide + validar incidentes, ver zonas asignadas.
- `researcher`: lectura extendida y validaciones cientificas.
- `moderator`: moderar feed, comentarios y reportes.
- `admin`: claims, catalogos, zonas, configuracion, exportaciones.

### Datos sensibles

- Para especies vulnerables o nidos, el feed publico usa ubicacion redondeada o
  `zoneId`, nunca GPS exacto.
- Fotos deben limpiarse de EXIF si el flujo de procesamiento se implementa.
- Auditoria append-only para cambios de status, validaciones y moderacion.

## 7. Consultas por Pantalla

### Agenda

- Stream/query de `dailyAgendas/{uid_yyyyMMdd}`.
- Fallback: `tours` y `events` por rango de dia y usuario/visibilidad.
- Tarjeta clima puede seguir local, pero conviene cachear clima por zona si se
  requiere consistencia institucional.

### Muro

- Eventos proximos: `events where visibility in [...] and startAt >= now`.
- Feed: `publicFeed orderBy createdAt desc limit 20`.
- Comentarios: subcoleccion paginada por card.

### Perfil

- Perfil: `users/{uid}`.
- Stats: `userStats/{uid}`.
- Muro personal: `fieldRecords where authorId == uid orderBy createdAt desc`.

### Dashboard

- `globalStats/current`.
- `leaderboards/current/entries`.
- `speciesStats` top N.
- `zoneStats` top N.

### Reporte

- `monthlyReports/{yyyyMM}` con KPIs materializados.
- Para analitica avanzada: BigQuery + Looker Studio, no consultas caras desde
  Flutter.

## 8. Indices Firestore Iniciales

- `fieldRecords`: `authorId asc, createdAt desc`.
- `fieldRecords`: `zoneId asc, observedAt desc`.
- `fieldRecords`: `category asc, createdAt desc`.
- `publicFeed`: `createdAt desc`.
- `events`: `visibility asc, startAt asc`.
- `events`: `status asc, startAt asc`.
- `tours`: `createdBy asc, startAt asc`.
- `tours`: `assignedGuideIds array, startAt asc`.
- `leaderboards/*/entries`: `score desc`.

## 9. Fases de Implementacion

### Fase 0 - Fundacion

- Confirmar region Firestore/Functions.
- Instalar Firebase CLI y configurar emuladores.
- Agregar dependencias Flutter: `cloud_functions`, `firebase_app_check`,
  `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics`.
- Crear repositorios Dart: `FieldRecordRepository`, `TourRepository`,
  `EventRepository`, `StatsRepository`.
- Corregir controladores de formularios y validaciones de UI.

### Fase 1 - Guardado real MVP

- Implementar `create_field_record`, `create_tour`, `create_event`.
- Guardar documentos canonicos con timestamps de servidor.
- Conectar Agenda, Muro y Perfil a Firestore.
- Reemplazar datos demo por estados vacios/carga/error/reales.
- Subir evidencia inicial a Storage con ruta controlada.

### Fase 2 - Feed, comentarios y eventos

- Crear `publicFeed`.
- Implementar reacciones, comentarios, inscripcion a eventos.
- Notificaciones FCM para comentarios, validaciones y eventos proximos.

### Fase 3 - Estadisticas y rankings

- Triggers de agregados por usuario, especie, zona y global.
- Materializar `userStats`, `globalStats`, `leaderboards`.
- Conectar Dashboard y Reporte.

### Fase 4 - Integridad cientifica

- Deteccion de duplicados por especie, geohash y ventana temporal.
- Score de integridad.
- Validacion por pares y revision de moderador.
- Mascaramiento automatico de ubicacion sensible.

### Fase 5 - Operacion de primer nivel

- CI/CD con tests.
- Alertas de errores y presupuesto.
- Backups/exports.
- BigQuery/Looker Studio.
- Politicas de retencion y eliminacion.

## 10. Testing y Calidad

- Unit tests Python para validadores y calculos de integridad.
- Emulator tests para callable functions.
- Tests de reglas Firestore/Storage.
- Tests Flutter de repositories con emuladores.
- Pruebas manuales de flujos:
  - usuario nuevo completa perfil;
  - guarda avistamiento con foto;
  - aparece en Muro;
  - aparece en Perfil;
  - stats cambian;
  - evento aparece en Agenda;
  - usuario sin permiso no lee GPS sensible.

## 11. Criterios de Produccion

- App Check activado y monitoreado.
- Reglas Firestore/Storage restrictivas.
- No hay colecciones criticas con `allow write` directo general.
- Todas las Functions validan auth y payload.
- Logs estructurados con `uid`, `function`, `recordId`, `severity`.
- Presupuesto y alertas de billing.
- Backups de Firestore o export programado.
- Dashboard de errores y latencia.
- Politica de datos sensibles documentada.

## 12. Referencias Oficiales

- Cloud Functions for Firebase callable Python:
  https://firebase.google.com/docs/functions/callable
- Triggers Firestore en Cloud Functions for Firebase:
  https://firebase.google.com/docs/functions/firestore-events
- Firebase Local Emulator Suite para Functions:
  https://firebase.google.com/docs/functions/get-started
- App Check en Flutter:
  https://firebase.google.com/docs/app-check/flutter/default-providers
- Firestore Security Rules:
  https://firebase.google.com/docs/firestore/security/rules-conditions
- Firebase Cloud Messaging:
  https://firebase.google.com/docs/cloud-messaging
- Cloud Scheduler con Cloud Run functions:
  https://cloud.google.com/scheduler/docs/tut-gcf-http

