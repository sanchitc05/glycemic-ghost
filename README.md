# Glycemic Ghost

A full-stack diabetes companion app that blends continuous glucose data, nutrition logging, and fitness signals into one experience.

Glycemic Ghost includes:
- A Node.js + Express backend for auth, glucose ingestion, food logging, and integrations
- A Flutter frontend for login, glucose trends, event history, and food impact tracking
- PostgreSQL, Redis, and InfluxDB for transactional, caching, and time-series workloads

---

## Why This Project Exists

Managing blood glucose is not only about sugar readings. Real outcomes depend on context: food, activity, medication, and timing.

Glycemic Ghost aims to provide that context in one place by combining:
- CGM readings (Dexcom integration + demo fallback)
- Meal and food impact logging
- Fitness metrics ingestion
- Historical event views for daily decisions

---

## Core Features

### Backend
- JWT-based authentication (register/login)
- Dexcom OAuth flow and EGV retrieval
- Food search and meal logging APIs
- Fitness metric ingestion endpoints
- Emergency contacts and alert settings endpoints
- SQL migrations runner

### Frontend (Flutter)
- Login / registration flow
- Glucose dashboard with chart and range filters
- Auto-refreshing glucose fetch cycle
- Event and history tabs (glucose, insulin, medication, meals, activity, fasting, notes)
- Food logging UX integrated with backend APIs
- Demo mode for quick app walkthrough

---

## Tech Stack

- Backend: Node.js, Express, PostgreSQL (pg), Redis (ioredis), InfluxDB client, Axios
- Frontend: Flutter (Dart), http, fl_chart, health
- Infra: Docker Compose (Postgres, InfluxDB, Redis)

---

## Repository Structure

~~~text
glycemic-ghost/
  backend/
    docker-compose.yml
    package.json
    src/
      app.js
      server.js
      migrate.js
      routes/
      services/
      migrations/
  frontend/
    glycemic_frontend/
      lib/
      pubspec.yaml
~~~

---

## Prerequisites

Install these before running locally:

- Node.js 18+
- npm 9+
- Flutter SDK 3.10+
- Dart SDK (bundled with Flutter)
- Docker Desktop (for Postgres, Redis, InfluxDB)

Optional but recommended:
- Git
- Postman or Bruno (API testing)

---

## Environment Configuration (Backend)

Use the template file at backend/.env.example and create your local backend/.env from it.

Windows (PowerShell):

~~~powershell
Copy-Item backend/.env.example backend/.env
~~~

macOS/Linux:

~~~bash
cp backend/.env.example backend/.env
~~~

Then edit backend/.env with your actual credentials.

> Important: Do not commit real credentials to source control.

~~~env
# App
PORT=4000
JWT_SECRET=replace-with-a-strong-secret

# Databases
POSTGRES_URL=postgresql://ghost:ghost@localhost:5432/ghost
REDIS_URL=redis://localhost:6379

# InfluxDB
INFLUX_URL=http://localhost:8086
INFLUX_TOKEN=dev-token
INFLUX_ORG=ghost-org
INFLUX_BUCKET=ghost-cgm

# Dexcom OAuth (sandbox for local development)
DEXCOM_BASE_URL=https://sandbox-api.dexcom.com
DEXCOM_CLIENT_ID=your-dexcom-client-id
DEXCOM_CLIENT_SECRET=your-dexcom-client-secret
DEXCOM_REDIRECT_URI=http://localhost:4000/api/dexcom/callback
DEXCOM_SCOPE=offline_access
~~~

If you are using a managed Postgres provider (for example Neon), keep POSTGRES_URL pointed to that database instead of localhost.

Note: backend/.env is ignored by git, while backend/.env.example is versioned for teammate onboarding.

---

## Run Locally (Backend + Frontend)

### 1) Start infrastructure services

From backend directory:

~~~bash
cd backend
docker compose up -d
~~~

This starts:
- Postgres on port 5432
- InfluxDB on port 8086
- Redis on port 6379

### 2) Create backend environment file

~~~powershell
Copy-Item backend/.env.example backend/.env
~~~

Update backend/.env values before starting the API.

### 3) Install backend dependencies

~~~bash
cd backend
npm install
~~~

### 4) Run backend migrations

~~~bash
cd backend
npm run migrate
~~~

### 5) Start backend API server

Development mode:

~~~bash
cd backend
npm run dev
~~~

Production mode:

~~~bash
cd backend
npm start
~~~

Backend health check:

~~~text
GET http://localhost:4000/health
~~~

### 6) Install frontend dependencies

~~~bash
cd frontend/glycemic_frontend
flutter pub get
~~~

### 7) Run Flutter app

~~~bash
cd frontend/glycemic_frontend
flutter run
~~~

For web specifically:

~~~bash
flutter run -d chrome
~~~

---

## Frontend API Base URL Note

The current Flutter code uses http://localhost:4000 as backend base URL.

If you run on:
- Android emulator: use http://10.0.2.2:4000
- Physical device: use your machine LAN IP, for example http://192.168.1.10:4000

Update the hardcoded API host values in Flutter services/screens accordingly when needed.

---

## Common API Surface

Base path: /api

- Auth
  - POST /auth/register
  - POST /auth/login
- Dexcom
  - GET /dexcom/connect?userId=<id>
  - GET /dexcom/callback
  - GET /dexcom/egvs?userId=<id>
- Fitness (auth required)
  - POST /fitness/metrics/bulk
  - GET /fitness/metrics
  - POST /fitness/metrics
- Food (auth required)
  - GET /food/search?q=<query>
  - POST /food/log
- Emergency
  - GET /emergency/contacts/:userId
  - POST /emergency/contacts/:userId
  - DELETE /emergency/contacts/:userId/:contactId
  - GET /emergency/settings/:userId
  - PUT /emergency/settings/:userId

---

## Development Workflow

Typical local cycle:

1. Start docker services
2. Run backend migrations
3. Start backend server
4. Start Flutter app
5. Test login and glucose dashboard

---

## Troubleshooting

### Docker services not starting
- Check Docker Desktop is running
- Ensure ports 5432, 6379, and 8086 are free
- Retry: docker compose down ; docker compose up -d

### Backend fails to connect to Postgres
- Verify POSTGRES_URL in backend/.env
- Confirm database is reachable and credentials are valid
- Re-run migrations after DB is fixed

### Flutter app cannot hit backend
- Ensure backend is listening on port 4000
- If using emulator/device, replace localhost with correct host
- Check firewall rules on your machine

### Dexcom login flow fails
- Validate DEXCOM_CLIENT_ID, DEXCOM_CLIENT_SECRET, and redirect URI
- Ensure redirect URI in Dexcom app settings matches backend .env exactly

---

## Security Notes

- Never commit real secrets in backend/.env or any .env.* file
- Keep only sanitized templates (for example backend/.env.example) in git
- .gitignore includes patterns for environment files, keys/certs, signing files, and credential JSON artifacts
- Rotate JWT and provider credentials periodically
- Add stricter CORS, rate limiting, and production-grade secret management before deployment

---

## Roadmap Ideas

- Real-time glucose alerting
- Better data visualizations and trend explanations
- Push notifications for high/low risk thresholds
- Enhanced offline support in Flutter app
- End-to-end tests for auth + logging flows

---

## Contributing

1. Create a feature branch
2. Keep PRs focused and small
3. Add migration files for schema changes
4. Include test evidence (screenshots/logs) for UI/API changes

---

## License

No license file is currently defined in this repository.
If you plan to open-source this project, add a LICENSE file (for example MIT or Apache-2.0).
