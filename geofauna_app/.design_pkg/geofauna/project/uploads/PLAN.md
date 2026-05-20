# PLAN.md - EcoGuia Galapagos

## 1. Vision del producto

EcoGuia Galapagos sera una app Flutter para Android e iOS que combina red social, bitacora de campo, registro de rutas, agenda, eventos, validacion comunitaria y reportes ambientales. La app esta pensada para guias naturalistas, guardaparques, investigadores, moderadores, administradores y visitantes.

La app debe funcionar en campo aun sin internet. Los usuarios podran registrar avistamientos con GPS, fotos, videos o audio; trazar rutas automaticamente; crear eventos; comentar; confirmar datos; denunciar informacion falsa; ganar XP; participar en rankings; y consultar estadisticas comunitarias.

El enfoque principal sera offline-first: la informacion critica se guarda primero en el dispositivo y luego se sincroniza con Firebase cuando haya conexion.

## 2. Alcance del MVP

El MVP incluye todos los modulos principales:

- Autenticacion con email/password y Google.
- Roles: admin, moderador, guia, guardaparque, investigador y visitante.
- Muro social con posts, avistamientos, comentarios, reacciones, confirmaciones y denuncias.
- Registro de campo con GPS obligatorio, evidencia multimedia y categorias.
- Rutas con tracking GPS en segundo plano.
- Eventos con cupos, lista de espera, inscripcion y asistencia.
- Agenda personal conectada a eventos, tours y asignaciones.
- Catalogo de especies administrado desde panel web.
- Gamificacion con XP, rachas, insignias y rankings.
- Reportes semanales generados por Cloud Functions.
- Panel admin en Next.js.
- Backup privado cifrado tipo WhatsApp usando Google Drive en Android y iCloud en iOS.
- Mapas offline de Galapagos.

## 3. Decisiones confirmadas

### Usuarios y roles

- La app sera para guias/guardaparques y tambien para turistas/visitantes.
- Los usuarios se registran directamente con email/password o Google.
- Los visitantes pueden publicar, ver, comentar, confirmar y participar.
- Existiran roles diferenciados.
- Los guias y expertos tendran mas peso que visitantes en la validacion.

### Offline

- La app debe funcionar sin internet durante rutas completas.
- Las rutas se trazan automaticamente con GPS en segundo plano.
- Se registra velocidad, distancia, duracion y puntos GPS.
- Una ruta puede tener varios avistamientos asociados.
- Se necesitan mapas offline de Galapagos.

### Fotos, videos y backup

- Las fotos originales quedan en el dispositivo.
- La red social necesita una copia optimizada en Firebase Storage para que otros usuarios puedan verla.
- Si el autor borra una foto local, la publicacion debe seguir visible en el muro.
- Al cambiar de telefono, el usuario podra restaurar desde su cuenta.
- El backup privado se hara como WhatsApp:
  - Android: Google Drive.
  - iOS: iCloud.
  - Periodicidad configurable: manual, diaria, semanal o mensual.
  - Opcion "solo WiFi".
  - Cifrado antes de subir.
- Los videos tendran limite recomendado de 30 a 60 segundos.
- No se requiere marca de agua, fecha, GPS visible ni firma digital sobre la imagen.

### Avistamientos y validacion

- Cada avistamiento requiere GPS obligatorio.
- No se permite editar ubicacion manualmente.
- Se buscara la maxima precision disponible del dispositivo.
- No se ocultaran ubicaciones por especie en esta version.
- Categorias: fauna, flora, incidente y basura.
- El catalogo de especies sera cargado por admins.
- No se agregara IA para sugerir especies en esta fase.
- Se permitiran fotos, videos y audio.
- Estados de avistamiento: pendiente, confirmado, rechazado y en revision.
- Validacion comunitaria y por expertos.
- Regla inicial de confirmacion:
  - Avistamiento normal: 3 confirmaciones comunitarias ponderadas.
  - Especies importantes o reportes sensibles: 3 confirmaciones comunitarias + 1 experto.
- La comunidad puede proponer correcciones.
- Habra denuncias para reportes falsos o problematicos.

### Gamificacion

- Habra XP, rachas, insignias y rankings.
- Dan puntos: publicar, confirmar, comentar, asistir a eventos, completar rutas y reportar incidentes.
- Rankings publicos para todos.
- Rankings mensual, historico y por categoria.
- Se necesitan controles anti-spam.

### Eventos y agenda

- Todos pueden crear eventos.
- Los usuarios pueden inscribirse.
- Habra cupos, lista de espera y asistencia confirmada.
- Los eventos se conectan con agenda personal.
- Se enviaran recordatorios push.
- La agenda viene de eventos, tours propios y asignaciones oficiales.
- Iniciar ruta activa tracking GPS.
- No se asociaran tours a pasajeros, embarcacion o agencia en esta version.

### Reportes y administracion

- El admin necesita reportes de interaccion en la app.
- Los reportes se calculan semanalmente.
- Se exportaran datos para investigacion.
- Todos pueden ver estadisticas comunitarias.
- Cloud Functions generara resumenes semanales.
- El panel admin sera en Next.js.
- Firestore sera la base principal.

## 4. Arquitectura general

```text
Flutter Android/iOS
  |
  |-- Base local offline-first
  |     |-- posts cacheados
  |     |-- avistamientos pendientes
  |     |-- rutas y puntos GPS
  |     |-- media local
  |     |-- cola de sincronizacion
  |     |-- catalogo de especies offline
  |
  |-- Firebase
  |     |-- Firebase Auth
  |     |-- Cloud Firestore
  |     |-- Firebase Storage
  |     |-- Cloud Functions
  |     |-- Firebase Cloud Messaging
  |     |-- Firebase App Check
  |
  |-- Backups privados
        |-- Google Drive en Android
        |-- iCloud en iOS

Next.js Admin Panel
  |
  |-- Firebase Auth
  |-- Firestore Admin SDK / callable functions
  |-- Moderacion, roles, especies, reportes
```

## 5. Stack recomendado

### App movil

- Flutter.
- Riverpod o Bloc para estado.
- GoRouter para navegacion.
- Drift o Isar para base local.
- Firebase Auth.
- Cloud Firestore.
- Firebase Storage.
- Firebase Cloud Messaging.
- Firebase App Check.
- Google Maps, Mapbox o MapLibre segun decision de mapas offline.
- Background geolocation para tracking de rutas.
- WorkManager en Android y BGTaskScheduler en iOS para sincronizacion y backups.

### Backend Firebase

- Firestore como base principal.
- Storage para media social optimizada.
- Cloud Functions v2 para procesos backend.
- Cloud Scheduler para reportes semanales.
- FCM para notificaciones.
- Security Rules estrictas por rol.

### Panel admin

- Next.js.
- Firebase Auth.
- Firebase Admin SDK en backend server-side.
- Hosting en Firebase Hosting, Vercel o Cloud Run.
- Componentes para moderacion, especies, usuarios, reportes y configuracion de XP.

## 6. Politica de almacenamiento multimedia

Hay dos flujos separados.

### 6.1 Media social

Uso: mostrar contenido en muro, perfil, avistamientos, reportes y comentarios.

Se guarda en Firebase Storage:

- Imagen optimizada para feed.
- Thumbnail.
- Video comprimido con limite 30 a 60 segundos.
- Audio comprimido si aplica.
- Metadata en Firestore.

Ejemplo de rutas Storage:

```text
social_media/{postId}/thumb.jpg
social_media/{postId}/image_1080.jpg
social_media/{postId}/video.mp4
social_media/{postId}/audio.m4a
profile_media/{userId}/avatar.jpg
species_media/{speciesId}/cover.jpg
```

Reglas:

- El original puede quedar solo local.
- La copia social debe quedar en Firebase Storage para que la publicacion siga visible.
- Cloud Functions genera thumbnails y valida tamano/formato.
- Si un post se elimina, se puede borrar la media social asociada.
- Si el usuario borra la foto local, el post no se rompe.

### 6.2 Backup privado tipo WhatsApp

Uso: restaurar cuenta y media al cambiar de telefono.

No se usa para alimentar el muro social.

Destino:

- Android: Google Drive del usuario.
- iOS: iCloud del usuario.

Caracteristicas:

- Cifrado antes de subir.
- Periodicidad: manual, diaria, semanal o mensual.
- Solo WiFi opcional.
- Incluye base local, media original, rutas pendientes y configuracion local.
- Restauracion despues de login.

Nota tecnica importante: si el backup es cifrado extremo a extremo, el servidor no debe poder leerlo. Por eso el backup privado no sirve para generar thumbnails, reportes o alimentar el muro. Para eso existe la media social en Firebase Storage.

## 7. Modelo de datos Firestore

### users

```json
{
  "displayName": "Carlos Jaramillo",
  "email": "c.jaramillo@example.com",
  "photoUrl": "https://...",
  "role": "guide",
  "secondaryRoles": ["expert"],
  "userType": "guia",
  "status": "active",
  "specialty": "Fauna terrestre",
  "sector": "Santa Cruz",
  "bio": "",
  "xp": 2400,
  "level": 12,
  "streakDays": 12,
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "lastActiveAt": "timestamp",
  "settings": {
    "language": "es",
    "darkMode": false,
    "pushFieldAlerts": true,
    "pushWallMessages": true,
    "backupFrequency": "weekly",
    "backupWifiOnly": true
  }
}
```

Roles posibles:

- `admin`
- `moderator`
- `guide`
- `ranger`
- `researcher`
- `expert`
- `visitor`

### species_catalog

```json
{
  "commonName": "Tortuga gigante",
  "scientificName": "Chelonoidis niger",
  "category": "fauna",
  "status": "active",
  "conservationStatus": "vulnerable",
  "description": "",
  "aliases": ["Tortuga Galapagos"],
  "createdBy": "adminUserId",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### sightings

```json
{
  "authorId": "userId",
  "routeId": "routeId|null",
  "postId": "postId|null",
  "category": "fauna",
  "speciesId": "speciesId|null",
  "speciesNameRaw": "Chelonoidis nigra",
  "quantity": 1,
  "notes": "Texto del usuario",
  "status": "pending",
  "validationScore": 0,
  "requiredExpertValidation": false,
  "location": {
    "geopoint": "GeoPoint",
    "accuracyMeters": 4.8,
    "altitude": 12,
    "source": "gps"
  },
  "media": {
    "thumbUrl": "https://...",
    "imageUrl": "https://...",
    "videoUrl": null,
    "audioUrl": null
  },
  "recordedAt": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "deletedAt": null
}
```

### posts

```json
{
  "authorId": "userId",
  "type": "sighting",
  "sightingId": "sightingId|null",
  "routeId": "routeId|null",
  "eventId": "eventId|null",
  "text": "Contenido del post",
  "visibility": "public",
  "status": "active",
  "media": {
    "thumbUrl": "https://...",
    "imageUrl": "https://...",
    "videoUrl": null,
    "audioUrl": null
  },
  "counts": {
    "comments": 0,
    "reactions": 0,
    "confirmations": 0,
    "reports": 0
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### comments

```json
{
  "postId": "postId",
  "authorId": "userId",
  "text": "Comentario",
  "status": "active",
  "parentCommentId": null,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### reactions

```json
{
  "postId": "postId",
  "userId": "userId",
  "type": "like",
  "createdAt": "timestamp"
}
```

### confirmations

```json
{
  "sightingId": "sightingId",
  "postId": "postId",
  "userId": "userId",
  "userRoleAtTime": "guide",
  "weight": 2,
  "status": "valid",
  "createdAt": "timestamp"
}
```

Pesos iniciales:

- Visitante: 1.
- Guia/guardaparque: 2.
- Investigador/experto: 3.
- Moderador/admin: 4.

Regla inicial:

- Confirmacion normal: score >= 6 y al menos 3 usuarios distintos.
- Especie importante: score >= 6, al menos 3 usuarios distintos y 1 confirmacion de experto.

### reports

```json
{
  "targetType": "post",
  "targetId": "postId",
  "sightingId": "sightingId|null",
  "reporterId": "userId",
  "reason": "false_information",
  "description": "Detalle opcional",
  "status": "pending",
  "reviewedBy": null,
  "createdAt": "timestamp",
  "resolvedAt": null
}
```

### corrections

```json
{
  "sightingId": "sightingId",
  "proposedBy": "userId",
  "field": "speciesId",
  "oldValue": "speciesA",
  "newValue": "speciesB",
  "reason": "Correccion comunitaria",
  "status": "pending",
  "reviewedBy": null,
  "createdAt": "timestamp",
  "resolvedAt": null
}
```

### routes

```json
{
  "authorId": "userId",
  "title": "Ruta Seymour Norte",
  "status": "completed",
  "startedAt": "timestamp",
  "endedAt": "timestamp",
  "distanceMeters": 4820,
  "durationSeconds": 7200,
  "avgSpeedMps": 0.66,
  "maxSpeedMps": 2.1,
  "pointsCount": 340,
  "sightingsCount": 5,
  "visibility": "public",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### route_points

Para alto volumen se recomienda subcoleccion por ruta o coleccion particionada.

```json
{
  "routeId": "routeId",
  "authorId": "userId",
  "location": "GeoPoint",
  "accuracyMeters": 5.2,
  "speedMps": 0.7,
  "altitude": 18,
  "recordedAt": "timestamp"
}
```

Alternativa para reducir costos: guardar puntos comprimidos en chunks:

```text
routes/{routeId}/point_chunks/{chunkId}
```

Cada chunk puede contener 50 a 200 puntos.

### events

```json
{
  "creatorId": "userId",
  "title": "Limpieza de Playa",
  "description": "Remocion de microplasticos",
  "type": "cleanup",
  "visibility": "public",
  "locationName": "Tortuga Bay",
  "location": "GeoPoint",
  "startsAt": "timestamp",
  "endsAt": "timestamp",
  "capacity": 30,
  "attendeeCount": 0,
  "waitlistCount": 0,
  "status": "active",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### event_attendees

```json
{
  "eventId": "eventId",
  "userId": "userId",
  "status": "registered",
  "checkedIn": false,
  "joinedAt": "timestamp",
  "checkedInAt": null
}
```

Estados:

- `registered`
- `waitlisted`
- `cancelled`
- `attended`

### agenda_items

```json
{
  "userId": "userId",
  "sourceType": "event",
  "sourceId": "eventId",
  "title": "Workshop: Corales",
  "startsAt": "timestamp",
  "endsAt": "timestamp",
  "status": "upcoming",
  "createdAt": "timestamp"
}
```

### xp_ledger

```json
{
  "userId": "userId",
  "action": "create_sighting",
  "points": 10,
  "sourceType": "sighting",
  "sourceId": "sightingId",
  "createdAt": "timestamp",
  "dedupeKey": "create_sighting:sightingId:userId"
}
```

### rankings_weekly

```json
{
  "weekId": "2026-W21",
  "category": "fauna",
  "entries": [
    {
      "userId": "userId",
      "displayName": "Elena R.",
      "photoUrl": "https://...",
      "points": 421,
      "rank": 1
    }
  ],
  "generatedAt": "timestamp"
}
```

### admin_reports_weekly

```json
{
  "weekId": "2026-W21",
  "totals": {
    "activeUsers": 120,
    "posts": 540,
    "sightings": 310,
    "comments": 980,
    "confirmations": 760,
    "reports": 12,
    "eventsCreated": 18,
    "routesCompleted": 90
  },
  "topSpecies": [],
  "topZones": [],
  "generatedAt": "timestamp"
}
```

## 8. Base local offline-first

La app debe tener una base local para que el usuario pueda trabajar sin internet.

Tablas/colecciones locales:

- `local_user_profile`
- `local_species_catalog`
- `local_posts_cache`
- `local_sightings`
- `local_routes`
- `local_route_points`
- `local_events_cache`
- `local_agenda`
- `local_media`
- `sync_queue`
- `backup_state`

### Cola de sincronizacion

Cada accion offline crea una tarea:

```json
{
  "id": "uuid",
  "type": "create_sighting",
  "payload": {},
  "mediaLocalPaths": [],
  "status": "pending",
  "attempts": 0,
  "createdAt": "timestamp",
  "lastAttemptAt": null
}
```

Reglas:

- Se sincroniza primero metadata, luego media.
- Si falla media, el post queda en estado `uploading_media`.
- Si falla Firestore, se reintenta con backoff.
- La UI debe mostrar estados: pendiente, sincronizando, subido, error.

## 9. Cloud Functions

Funciones principales:

### Auth y usuarios

- `onUserCreate`: crea documento `users`.
- `setUserRole`: callable solo admin.
- `updateUserStats`: recalcula stats agregadas.

### Media

- `onSocialMediaUpload`: valida formato/tamano.
- `generateThumbnail`: genera thumbnail para imagen/video.
- `markPostMediaReady`: actualiza post cuando media esta lista.

### Avistamientos

- `onSightingCreate`: asigna XP inicial, crea post si corresponde.
- `onConfirmationCreate`: recalcula score y estado.
- `onCorrectionCreate`: notifica a moderadores/expertos.
- `onReportCreate`: aumenta contador y puede pasar a revision.

### Gamificacion

- `awardXp`: centraliza puntos con dedupe.
- `recalculateUserLevel`: actualiza nivel.
- `generateWeeklyRankings`: ranking semanal.
- `generateMonthlyRankings`: ranking mensual.

### Eventos

- `joinEvent`: controla cupos y lista de espera.
- `cancelEventAttendance`: libera cupo.
- `eventReminderScheduler`: agenda notificaciones.
- `checkInEvent`: confirma asistencia y otorga XP.

### Reportes

- `generateWeeklyAdminReport`: calcula interacciones semanales.
- `exportResearchDataset`: genera CSV/JSON para investigacion.

### Notificaciones

- Nuevo comentario.
- Confirmacion de avistamiento.
- Avistamiento confirmado/rechazado.
- Evento proximo.
- Cambio de lista de espera a inscrito.
- Denuncia resuelta.

## 10. Reglas de seguridad

### Principios

- Todo usuario autenticado puede leer contenido publico activo.
- Cada usuario puede editar su propio perfil limitado.
- Solo admins/moderadores pueden cambiar roles, resolver denuncias y editar catalogo global.
- Los usuarios pueden crear posts, avistamientos, comentarios, confirmaciones y denuncias.
- No se permite editar ubicacion de avistamiento una vez creado.
- Las escrituras sensibles deben pasar por Cloud Functions.

### Ejemplo conceptual Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function userDoc() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid));
    }

    function role() {
      return userDoc().data.role;
    }

    function isAdmin() {
      return signedIn() && role() == 'admin';
    }

    function isModerator() {
      return signedIn() && (role() == 'admin' || role() == 'moderator');
    }

    match /users/{userId} {
      allow read: if signedIn();
      allow create: if signedIn() && request.auth.uid == userId;
      allow update: if signedIn() && request.auth.uid == userId
        && !('role' in request.resource.data.diff(resource.data).changedKeys());
      allow update: if isAdmin();
    }

    match /species_catalog/{speciesId} {
      allow read: if signedIn();
      allow write: if isAdmin() || isModerator();
    }

    match /posts/{postId} {
      allow read: if signedIn() && resource.data.status == 'active';
      allow create: if signedIn() && request.resource.data.authorId == request.auth.uid;
      allow update: if signedIn() && resource.data.authorId == request.auth.uid;
      allow update: if isModerator();
    }

    match /sightings/{sightingId} {
      allow read: if signedIn();
      allow create: if signedIn()
        && request.resource.data.authorId == request.auth.uid
        && request.resource.data.location.source == 'gps';
      allow update: if isModerator();
    }

    match /comments/{commentId} {
      allow read: if signedIn();
      allow create: if signedIn() && request.resource.data.authorId == request.auth.uid;
      allow update, delete: if signedIn() && resource.data.authorId == request.auth.uid;
      allow update, delete: if isModerator();
    }

    match /confirmations/{confirmationId} {
      allow read: if signedIn();
      allow create: if signedIn() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isModerator();
    }

    match /reports/{reportId} {
      allow create: if signedIn() && request.resource.data.reporterId == request.auth.uid;
      allow read, update: if isModerator();
    }

    match /events/{eventId} {
      allow read: if signedIn();
      allow create: if signedIn() && request.resource.data.creatorId == request.auth.uid;
      allow update: if signedIn() && resource.data.creatorId == request.auth.uid;
      allow update: if isModerator();
    }
  }
}
```

Nota: estas reglas son guia inicial. La implementacion final debe validar campos permitidos con `diff()`, tipos, limites y paths exactos.

## 11. Reglas anti-spam y calidad

### XP

Puntos iniciales propuestos:

- Crear avistamiento con GPS y evidencia: +10.
- Avistamiento confirmado: +20.
- Confirmar avistamiento valido: +3.
- Comentario: +1.
- Comentario marcado util por autor/moderador: +3.
- Completar ruta: +10.
- Crear evento con asistentes reales: +10.
- Asistir a evento confirmado: +15.
- Reporte de incidente confirmado: +20.

### Limites anti-spam

- Comentarios dan XP solo hasta 10 veces por dia.
- Confirmaciones dan XP solo si el avistamiento termina confirmado.
- No se da XP por confirmar publicaciones propias.
- No se da XP por multiples avistamientos iguales en mismo radio y ventana corta.
- Media duplicada se marca para revision.
- Usuarios nuevos tienen peso de confirmacion reducido durante los primeros dias.
- Denuncias validas contra un usuario reducen reputacion.
- Reportes rechazados repetidamente reducen XP o peso de validacion.

### Reputacion

Ademas del XP visible, usar un `trustScore` interno.

Factores positivos:

- Avistamientos confirmados.
- Confirmaciones correctas.
- Asistencia real a eventos.
- Baja tasa de denuncias validas.

Factores negativos:

- Avistamientos rechazados.
- Denuncias confirmadas.
- Spam de comentarios.
- Media falsa o repetida.

## 12. Mapas offline y tracking

Requisitos:

- Descargar paquete offline de Galapagos.
- Mostrar ubicacion actual.
- Guardar puntos GPS en segundo plano.
- Asociar avistamientos a ruta activa.
- Pausar y reanudar ruta.
- Finalizar ruta y calcular resumen.

Datos por punto:

- Latitud/longitud.
- Precision.
- Velocidad.
- Altitud si disponible.
- Timestamp.

Optimizacion:

- Guardar puntos cada X metros o X segundos.
- Reducir puntos redundantes cuando el usuario esta quieto.
- Sincronizar puntos en chunks para no disparar costos de Firestore.

## 13. Panel admin Next.js

Modulos:

- Dashboard general.
- Gestion de usuarios y roles.
- Moderacion de posts.
- Revision de denuncias.
- Revision de correcciones comunitarias.
- Catalogo de especies.
- Eventos.
- Reportes semanales.
- Exportaciones CSV/JSON.
- Configuracion de XP y reglas anti-spam.

Permisos:

- Admin: todo.
- Moderador: moderacion, denuncias, correcciones.
- Investigador/experto: validar especies y revisar avistamientos.

## 14. Exportacion para investigacion

Formatos:

- CSV.
- JSON.

Datos exportables:

- Avistamientos confirmados.
- Categoria.
- Especie.
- Cantidad.
- Fecha/hora.
- Coordenadas.
- Precision GPS.
- Ruta asociada.
- Autor anonimizado opcional.
- Estado de validacion.
- Confirmaciones.

Privacidad:

- Para exportaciones publicas, anonimizar `authorId`.
- Para admins/investigadores autorizados, permitir dataset completo.

## 15. Notificaciones push

Eventos:

- Comentario nuevo en mi post.
- Confirmacion nueva.
- Avistamiento confirmado.
- Avistamiento rechazado.
- Denuncia resuelta.
- Invitacion o recordatorio de evento.
- Cupo disponible desde lista de espera.
- Resumen semanal.

Preferencias:

- Alertas de campo.
- Mensajes del muro.
- Eventos.
- Rankings.
- Reportes semanales.

## 16. Fases de implementacion

### Fase 0 - Fundacion

- Crear repo Flutter.
- Crear proyecto Firebase.
- Configurar Firebase Auth, Firestore, Storage, Functions, FCM y App Check.
- Definir tema visual basado en `gal_pagos_sentinel/DESIGN.md`.
- Definir navegacion base con tabs: Inicio, Agenda, Nuevo, Muro, Perfil.
- Crear modelos Dart principales.
- Crear base local.

Entregable: app abre, login funciona, navegacion base y tema listos.

### Fase 1 - Auth, perfiles y roles

- Registro email/password.
- Login con Google.
- Creacion automatica de perfil.
- Edicion basica de perfil.
- Roles y permisos iniciales.
- Configuracion de cuenta.

Entregable: usuarios reales con perfil y rol.

### Fase 2 - Catalogo de especies y admin base

- Panel Next.js inicial.
- Login admin.
- CRUD de especies.
- CRUD de roles.
- Sincronizacion de catalogo a la app.
- Cache offline del catalogo.

Entregable: admins cargan especies y la app las consume offline.

### Fase 3 - Registro de campo

- Captura GPS obligatoria.
- Registro de categoria.
- Selector de especie.
- Cantidad, notas, fecha/hora.
- Captura foto/video/audio.
- Guardado local offline.
- Cola de sincronizacion.

Entregable: avistamiento se crea offline y sincroniza luego.

### Fase 4 - Media social y Storage

- Subida de imagen optimizada.
- Generacion de thumbnail.
- Video/audio con limite.
- Estados de subida.
- Reintentos.
- Reglas de Storage.

Entregable: publicaciones con media visible para otros usuarios.

### Fase 5 - Muro social

- Feed de posts.
- Comentarios.
- Reacciones.
- Confirmaciones.
- Denuncias.
- Filtros recientes/populares.
- Perfil con muro personal.

Entregable: red social funcional.

### Fase 6 - Validacion y moderacion

- Confirmaciones ponderadas por rol.
- Estados pendiente/confirmado/rechazado/en revision.
- Reglas 3 comunidad + 1 experto para especies importantes.
- Correcciones comunitarias.
- Panel de denuncias.
- Panel de revision experta.

Entregable: flujo de integridad de datos funcional.

### Fase 7 - Rutas y mapas offline

- Iniciar/pausar/finalizar ruta.
- Tracking GPS en segundo plano.
- Calculo de distancia, velocidad, duracion.
- Avistamientos asociados a ruta.
- Mapa offline de Galapagos.
- Sincronizacion por chunks.

Entregable: rutas completas sin internet.

### Fase 8 - Eventos y agenda

- Crear evento.
- Inscribirse.
- Cupos y lista de espera.
- Check-in/asistencia.
- Agenda personal.
- Recordatorios push.

Entregable: eventos conectados a agenda.

### Fase 9 - Gamificacion

- XP ledger.
- Rachas.
- Insignias.
- Rankings por categoria.
- Rankings semanal, mensual e historico.
- Reglas anti-spam.

Entregable: sistema de reputacion visible y controlado.

### Fase 10 - Reportes y exportaciones

- Reportes semanales.
- Dashboard comunitario.
- Exportacion CSV/JSON.
- Estadisticas de interaccion.
- Estadisticas por especie, zona y categoria.

Entregable: datos utiles para admins e investigacion.

### Fase 11 - Backup tipo WhatsApp

- Configuracion de backup.
- Cifrado local.
- Backup a Google Drive Android.
- Backup a iCloud iOS.
- Restauracion despues de login.
- Solo WiFi.
- Periodicidad configurable.

Entregable: usuario cambia de telefono y restaura datos privados.

### Fase 12 - Pulido y lanzamiento

- Pruebas en Android/iOS.
- Pruebas offline reales.
- Pruebas de bateria para tracking.
- Pruebas de reglas Firebase.
- Observabilidad y crash reporting.
- Preparacion para tiendas.

Entregable: version beta cerrada.

## 17. Riesgos tecnicos

### Backup cifrado Google Drive/iCloud

Riesgo: no es el mismo flujo que Firebase y requiere integraciones nativas distintas por plataforma.

Mitigacion:

- Implementarlo despues del core social.
- Separar backup privado de media social.
- Usar una interfaz comun en Flutter y codigo nativo por plataforma si hace falta.

### Tracking GPS en segundo plano

Riesgo: consumo de bateria y restricciones de iOS/Android.

Mitigacion:

- Permisos claros.
- Intervalos adaptativos.
- Reducir puntos redundantes.
- Probar en campo temprano.

### Costos de Firestore por route_points

Riesgo: demasiados puntos GPS pueden aumentar lecturas/escrituras.

Mitigacion:

- Guardar puntos en chunks.
- Sincronizar resumen de ruta.
- Descargar detalle solo al abrir ruta.

### Validacion comunitaria manipulable

Riesgo: usuarios pueden confirmar en grupo datos falsos.

Mitigacion:

- Peso por rol.
- Trust score.
- Expertos para especies importantes.
- Denuncias.
- Moderacion.

### Media pesada

Riesgo: videos y fotos elevan almacenamiento y transferencia.

Mitigacion:

- Compresion.
- Limite 30 a 60 segundos en video.
- Thumbnails.
- Subidas solo WiFi opcionales para backup.

## 18. Prioridad recomendada

Aunque el MVP objetivo incluye todo, el orden practico debe ser:

1. Auth + perfiles + roles.
2. Registro de campo offline.
3. Media social en Firebase Storage.
4. Muro social.
5. Validacion.
6. Rutas offline.
7. Eventos y agenda.
8. Gamificacion.
9. Reportes.
10. Panel admin completo.
11. Backup Google Drive/iCloud.

La razon: sin auth, registro, media social y sincronizacion offline no existe el producto base. El backup tipo WhatsApp es importante, pero depende de tener ya definida la estructura local que se va a respaldar.

## 19. Proxima lista de tareas

- Crear estructura Flutter.
- Definir nombres finales de roles.
- Definir campos obligatorios de perfil.
- Elegir base local: Drift o Isar.
- Elegir proveedor de mapas offline.
- Crear Firebase project.
- Escribir reglas iniciales Firestore/Storage.
- Crear Next.js admin shell.
- Convertir pantallas HTML existentes a widgets Flutter.
- Crear backlog por fase.

