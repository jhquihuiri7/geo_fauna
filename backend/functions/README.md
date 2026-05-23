# Cloud Functions Python

Este directorio es el punto de entrada propuesto para Cloud Functions for
Firebase v2 usando Python.

## Estructura prevista

- `main.py`: funciones callable y triggers.
- `requirements.txt`: dependencias Python.
- `models/`: contratos Pydantic cuando empiece la implementacion real.
- `services/`: Firestore, Storage, FCM, integridad, catalogos.
- `tests/`: unit tests y pruebas con emuladores.

## Setup local

Desde la raiz del repo:

```powershell
cd backend\functions
python -m venv venv
.\venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

Luego, desde `backend`:

```powershell
firebase emulators:start
```

## Deploy

El despliegue final deberia hacerse con Firebase CLI:

```powershell
firebase deploy --only functions
```

Antes de produccion, confirmar:

- Region de Firestore.
- Proyecto Firebase activo.
- Plan Blaze habilitado.
- App Check configurado.
- Reglas e indices desplegados.
