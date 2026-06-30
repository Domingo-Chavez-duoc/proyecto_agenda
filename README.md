# 📅 Calendar App — MVP

App de calendario/agenda multi-plataforma (Android, iOS, Web, Desktop).

## Stack

| Capa | Tecnología |
|------|-----------|
| Frontend | Flutter 3.22 (multi-platform) |
| HTTP client | `dio` (equivalente a axios para Dart) |
| State management | `provider` |
| Backend | Flask + flask-restx |
| Auth | JWT (`flask-jwt-extended`) |
| API Docs | Swagger auto-generado por flask-restx |
| Base de datos | PostgreSQL 16 |
| Containerización | Docker + Docker Compose |
| CI/CD | GitHub Actions → GHCR.io |

---

## Estructura del proyecto

```
proyecto_agenda/
├── backend/                    # Flask API
│   ├── app/
│   │   ├── __init__.py         # App factory + extensiones
│   │   ├── config.py           # Configuración por entorno
│   │   ├── models/
│   │   │   ├── user.py         # Entidad User (bcrypt passwords)
│   │   │   └── event.py        # Entidad Event
│   │   └── routes/
│   │       ├── auth.py         # POST /api/auth/register|login|refresh
│   │       ├── events.py       # CRUD /api/events/
│   │       └── users.py        # GET|PUT /api/users/me
│   ├── run.py
│   ├── requirements.txt
│   └── Dockerfile
│
├── frontend/                   # Flutter app
│   ├── lib/
│   │   ├── main.dart           # App + GoRouter + Providers
│   │   ├── core/
│   │   │   ├── api/
│   │   │   │   └── api_client.dart     # Dio client (axios equivalent)
│   │   │   ├── models/
│   │   │   │   ├── user.dart
│   │   │   │   └── event.dart
│   │   │   └── providers/
│   │   │       ├── auth_provider.dart
│   │   │       └── event_provider.dart
│   │   ├── features/
│   │   │   ├── auth/           # Login + Register screens
│   │   │   ├── calendar/       # Vista mensual con table_calendar
│   │   │   ├── agenda/         # Vista semanal
│   │   │   └── profile/        # Perfil de usuario
│   │   └── shared/
│   │       ├── widgets/
│   │       │   └── event_dialog.dart   # Modal crear/editar evento
│   │       └── theme/
│   │           └── app_theme.dart
│   ├── pubspec.yaml
│   └── Dockerfile
│
├── docker-compose.yml          # Dev local
├── docker-compose.prod.yml     # Producción (imágenes de GHCR)
├── .env.example
└── .github/
    └── workflows/
        └── ci-cd.yml           # CI → Tests → Build → Push GHCR → Deploy
```

---

## Levantar en local (desarrollo)

### Requisitos
- Docker + Docker Compose v2
- Flutter SDK 3.22+ (solo para desarrollo nativo Android/iOS/Desktop)

### 1. Clonar y configurar

```bash
git clone https://github.com/TU_USUARIO/calendar-app.git
cd calendar-app
cp .env.example .env
# Editar .env con tus valores
```

### 2. Levantar backend + DB

```bash
docker compose up db backend -d
```

La API estará disponible en:
- API: http://localhost:5000/api
- Swagger UI: http://localhost:5000/swagger

### 3. Frontend Flutter (nativo)

```bash
cd frontend
flutter pub get
flutter run -d chrome    # Web
flutter run -d android   # Android
flutter run -d ios       # iOS
flutter run -d macos     # macOS
```

### 4. Frontend como web containerizado

```bash
docker compose --profile web up -d
# Disponible en http://localhost:8080
```

---

## API Endpoints

### Auth
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/auth/register` | Registro de usuario |
| POST | `/api/auth/login` | Login → access + refresh tokens |
| POST | `/api/auth/refresh` | Renovar access token |

### Events (requieren `Authorization: Bearer <token>`)
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/events/` | Listar eventos (filtros: `?start=&end=`) |
| POST | `/api/events/` | Crear evento |
| GET | `/api/events/<id>` | Detalle de evento |
| PUT | `/api/events/<id>` | Actualizar evento |
| DELETE | `/api/events/<id>` | Eliminar evento |

### Users
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/users/me` | Perfil del usuario autenticado |
| PUT | `/api/users/me` | Actualizar nombre / avatar |
| PUT | `/api/users/me/password` | Cambiar contraseña |

---

## Flujo CI/CD

```
Push a main
    │
    ├─► Job 1: backend-ci
    │       ├── flake8 lint
    │       └── pytest (con PostgreSQL service)
    │
    ├─► Job 2: frontend-ci
    │       ├── flutter analyze
    │       ├── flutter test
    │       └── flutter build web (artifact)
    │
    ├─► Job 3: docker-build-push (solo si CI pasó)
    │       ├── Build backend → ghcr.io/ORG/calendar-backend:latest
    │       └── Build frontend → ghcr.io/ORG/calendar-frontend:latest
    │
    └─► Job 4: deploy
            └── SSH al VPS → docker compose pull + up
```

### Secrets necesarios en GitHub

| Secret | Descripción |
|--------|-------------|
| `GITHUB_TOKEN` | Auto-provisto por Actions (para GHCR) |
| `SERVER_HOST` | IP/hostname del VPS de producción |
| `SERVER_USER` | Usuario SSH |
| `SERVER_SSH_KEY` | Clave privada SSH |

### Variables de repositorio

| Variable | Ejemplo |
|----------|---------|
| `API_URL` | `https://api.tudominio.com/api` |

---

## Dio vs Axios — comparación

```dart
// Dart / Flutter (Dio)
final response = await apiClient.post('/events/', data: {
  'title': 'Reunión',
  'start_datetime': '2024-06-15T10:00:00',
  'end_datetime': '2024-06-15T11:00:00',
});
```

```javascript
// JavaScript (Axios)
const response = await axios.post('/events/', {
  title: 'Reunión',
  start_datetime: '2024-06-15T10:00:00',
  end_datetime: '2024-06-15T11:00:00',
});
```

Ambos soportan:
- Interceptores (auth headers, refresh token)
- Manejo de errores centralizado
- Timeout configurable
- Cancel tokens
- Multipart / file upload

---

## Próximos pasos para el MVP+

- [ ] Notificaciones push (Firebase FCM)
- [ ] Eventos recurrentes
- [ ] Compartir calendarios entre usuarios
- [ ] Sync con Google Calendar (OAuth2)
- [ ] Tests unitarios e integración (pytest + flutter_test)
- [ ] Migraciones DB con Flask-Migrate
