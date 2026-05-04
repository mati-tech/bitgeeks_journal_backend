# Trading Journal — Backend (Vertical Slice)

FastAPI + PostgreSQL backend for an AI-powered trading journal. This is the
**phase 1 vertical slice**: auth, trades CRUD, screenshot upload, analytics,
and AI-insights endpoints are all live. Flutter app comes in phase 2.

## What's in here

```
backend/
  app/
    main.py              # FastAPI app, CORS, lifespan (auto-creates tables)
    config.py            # Pydantic settings, reads .env
    database.py          # SQLAlchemy engine, session, declarative Base
    models/              # User, Trade, Insight ORM models
    schemas/             # Pydantic request/response models
    routers/
      auth.py            # POST /api/auth/{register,login}, GET /me
      trades.py          # CRUD + POST /{id}/screenshot
      analytics.py       # /summary, /performance, /by-{strategy,symbol}, /emotional-analysis
      insights.py        # POST /generate, GET/DELETE
    services/
      trade_service.py   # PnL computation
      ai_service.py      # Anthropic Claude analysis
    utils/
      security.py        # bcrypt + JWT
      dependencies.py    # get_current_user
  migrations/001_init.sql  # Reference schema (auto-created at startup too)
  Dockerfile
  requirements.txt
  .env.example
docker-compose.yml         # Postgres + backend
```

## API surface

| Method | Path | Purpose |
| --- | --- | --- |
| POST   | `/api/auth/register` | Create account, returns JWT |
| POST   | `/api/auth/login` | OAuth2 form (`username` = email), returns JWT |
| GET    | `/api/auth/me` | Current user |
| POST   | `/api/trades` | Create trade (auto-computes PnL if closed) |
| GET    | `/api/trades` | List with filters: symbol, strategy, status, date range |
| GET    | `/api/trades/{id}` | Single trade |
| PUT    | `/api/trades/{id}` | Partial update; recomputes PnL on close |
| DELETE | `/api/trades/{id}` | Deletes trade + screenshot file |
| POST   | `/api/trades/{id}/screenshot` | multipart upload, png/jpg/webp, ≤5 MB |
| GET    | `/api/analytics/summary` | Win rate, total PnL, best/worst, averages |
| GET    | `/api/analytics/performance?interval=day\|week\|month` | Time series + cumulative |
| GET    | `/api/analytics/by-strategy` | Grouped performance |
| GET    | `/api/analytics/by-symbol` | Grouped performance |
| GET    | `/api/analytics/emotional-analysis` | PnL by emotion tag |
| POST   | `/api/insights/generate?lookback=50` | Calls Claude, persists insights |
| GET    | `/api/insights` | List insights |
| GET    | `/api/insights/{id}` | Single insight |
| DELETE | `/api/insights/{id}` | Dismiss |

Interactive docs: <http://localhost:8000/docs>

## Running it — pick one path

### Path A: Docker (recommended)

Requires Docker Desktop running.

```bash
# from repo root
cp backend/.env.example backend/.env   # already done
docker compose up -d
# wait ~10s for postgres healthcheck, then:
curl http://localhost:8000/health
open http://localhost:8000/docs
```

The `migrations/001_init.sql` file is auto-loaded by Postgres on first boot
(via `/docker-entrypoint-initdb.d`). The backend also calls
`Base.metadata.create_all` at startup as a safety net.

### Path B: Local Python + local Postgres

Requires Postgres running locally and a database/user you can connect to.

```bash
# 1. Create the database (run as a postgres superuser)
psql -U postgres -c "CREATE USER tradingjournal WITH PASSWORD 'changeme';"
psql -U postgres -c "CREATE DATABASE tradingjournal OWNER tradingjournal;"
psql -U tradingjournal -d tradingjournal -f backend/migrations/001_init.sql

# 2. Install deps & run
cd backend
python -m venv .venv
.venv/Scripts/activate           # Windows
# source .venv/bin/activate      # macOS/Linux
pip install -r requirements.txt
uvicorn app.main:app --reload
```

If your Postgres is on a non-default user/password, edit `backend/.env`:

```
DATABASE_URL=postgresql+psycopg2://YOUR_USER:YOUR_PASSWORD@localhost:5432/tradingjournal
```

## Environment variables (`backend/.env`)

| Var | Default | Notes |
| --- | --- | --- |
| `DATABASE_URL` | postgres://tradingjournal:changeme@localhost:5432/tradingjournal | SQLAlchemy URL |
| `SECRET_KEY` | dev placeholder | **Change for production.** Use `python -c "import secrets; print(secrets.token_urlsafe(48))"` |
| `ALGORITHM` | HS256 | JWT alg |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | 10080 | 7 days |
| `ANTHROPIC_API_KEY` | empty | Required only for `/api/insights/generate`. Without it, that endpoint returns 503. |
| `UPLOAD_DIR` | `./uploads` | Screenshot storage root |
| `MAX_UPLOAD_SIZE_MB` | 5 | Per-screenshot cap |
| `CORS_ORIGINS` | `http://localhost:3000,http://localhost:8080` | Comma-separated |

## Quick smoke test (bash, after server is up)

```bash
# Register
curl -s -X POST http://localhost:8000/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"me@example.com","password":"hunter22hunter","full_name":"Demo"}' \
  | python -m json.tool

# Login (note: form-encoded, not JSON — OAuth2 spec)
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -d 'username=me@example.com&password=hunter22hunter' \
  | python -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# Create a closed trade (PnL auto-computed)
curl -s -X POST http://localhost:8000/api/trades \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "symbol":"BTC/USDT","trade_type":"LONG",
    "entry_price":"60000","exit_price":"62000",
    "position_size":"0.1","leverage":1,
    "entry_time":"2026-05-01T10:00:00Z","exit_time":"2026-05-01T14:00:00Z",
    "strategy":"Breakout","timeframe":"1h",
    "emotions":"confident","status":"closed"
  }' | python -m json.tool

# Summary
curl -s http://localhost:8000/api/analytics/summary \
  -H "Authorization: Bearer $TOKEN" | python -m json.tool
```

## Notes on the implementation

- **PnL is server-computed** when a trade transitions to `closed` and an
  `exit_price` is set. Direction-aware (LONG vs SHORT). Leverage multiplies
  the percentage return, not the USD figure.
- **Screenshots** are written to `./uploads/screenshots/{user_id}/{trade_id}.{ext}`
  and served as static files at `/uploads/...`. For production swap to S3.
- **AI insights** call Claude (`claude-sonnet-4-6`) with the user's last N trades
  and parse a JSON array. Without `ANTHROPIC_API_KEY` the endpoint returns
  503 with a clear message — the rest of the app is unaffected.
- **Tables auto-create** at startup via `Base.metadata.create_all`. For
  production, switch to Alembic migrations.

## What's NOT here yet (phase 2+)

- Flutter app
- Alembic migrations
- Tests (pytest scaffolding)
- Rate limiting on auth endpoints
- Refresh tokens
- S3 / cloud storage for screenshots
- Email verification / password reset
