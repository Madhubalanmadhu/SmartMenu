# Production Database

Use PostgreSQL for hosted SmartMenu deployments.

SQLite is fine for local development, but PostgreSQL is the better production
choice for this app because each restaurant owner has separate menu, sales,
waste, weather, prediction, and AI data that will grow over time.

## Recommended Providers

- Neon PostgreSQL
- Supabase PostgreSQL
- Render PostgreSQL
- Railway PostgreSQL

## Backend Setup

Set this environment variable on the backend host:

```env
DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/DB_NAME
```

Some hosts provide URLs that start with `postgres://`. The backend normalizes
that to `postgresql://` automatically.

## Local Development

Keep this in `backend/.env` when developing locally:

```env
DATABASE_URL=sqlite:///restaurant.db
```

## First Production Run

When the backend starts, SQLAlchemy creates the required tables automatically.
After deployment, test a fresh owner flow:

1. Sign up with Firebase.
2. Create a restaurant profile.
3. Add menu dishes.
4. Upload or enter sales.
5. Check analytics, AI assistant, and export data.

## Existing Local Data

The current local SQLite data will not automatically move to PostgreSQL.
For real customers this is usually good: every new hosted owner starts with
their own clean restaurant setup and dataset.
