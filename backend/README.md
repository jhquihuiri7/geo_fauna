# GeoFauna Backend

Plan y base inicial para construir el backend de `geofauna_app` sobre Firebase
y Google Cloud con Cloud Functions for Firebase v2 en Python.

## Objetivo

Convertir la app Flutter actual en una plataforma de primer nivel para
monitoreo de biodiversidad:

- Autenticacion y perfiles con Firebase Auth y Firestore.
- Persistencia real para registros de campo, tours y eventos.
- Muro comunitario, agenda y estadisticas alimentados por datos reales.
- Validacion de integridad, control de roles, auditoria y proteccion de datos
  sensibles.
- Backend serverless en Python con Cloud Functions, Firestore, Cloud Storage,
  App Check, FCM, Cloud Scheduler y observabilidad de Google Cloud.

## Archivos

- `BACKEND_PLAN_GCP.md`: analisis de la app, arquitectura propuesta,
  modelo de datos, funciones, reglas, fases y criterios de calidad.
- `functions/main.py`: esqueleto inicial de Cloud Functions Python con nombres
  de funciones y contratos previstos.
- `functions/requirements.txt`: dependencias base para Functions Python.
- `functions/README.md`: guia de trabajo local, emuladores y despliegue.
- `firebase.json` y `.firebaserc`: configuracion base para Firebase CLI.
- `firestore.rules`: borrador de reglas para Firestore.
- `storage.rules`: borrador de reglas para Cloud Storage for Firebase.
- `firestore.indexes.json`: indices iniciales esperados para las consultas.

## Decision Principal

Las escrituras importantes no deben hacerse directamente desde Flutter. El
cliente debe llamar funciones callable (`create_field_record`, `create_tour`,
`create_event`, etc.) y Firestore debe usarse principalmente para streams de
lectura en tiempo real. Esto permite validacion fuerte, timestamps de servidor,
control de cuotas, auditoria, sanitizacion y actualizacion consistente de
estadisticas.

## Primer Sprint Recomendado

1. Configurar Firebase Emulator Suite para Auth, Firestore, Storage y Functions.
2. Agregar `cloud_functions` y `firebase_app_check` a Flutter.
3. Implementar `create_field_record`, `create_tour` y `create_event`.
4. Reemplazar datos demo de Agenda, Muro y Perfil por streams de Firestore.
5. Activar reglas restrictivas y pruebas de reglas antes de produccion.
