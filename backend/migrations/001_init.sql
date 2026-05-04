-- Trading Journal — initial schema
-- Equivalent to what app.main creates via Base.metadata.create_all on startup.
-- Run this manually if you prefer not to rely on the auto-create behavior.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS trades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    symbol VARCHAR(50) NOT NULL,
    trade_type VARCHAR(10) NOT NULL,
    entry_price NUMERIC(20, 8) NOT NULL,
    exit_price NUMERIC(20, 8),
    position_size NUMERIC(20, 8) NOT NULL,
    leverage INTEGER NOT NULL DEFAULT 1,

    entry_time TIMESTAMPTZ NOT NULL,
    exit_time TIMESTAMPTZ,

    pnl NUMERIC(20, 4),
    pnl_percentage NUMERIC(10, 4),
    fees NUMERIC(20, 4) NOT NULL DEFAULT 0,

    strategy VARCHAR(100),
    timeframe VARCHAR(20),
    notes TEXT,
    emotions VARCHAR(255),
    screenshot_url VARCHAR(500),

    status VARCHAR(20) NOT NULL DEFAULT 'open',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    insight_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    severity VARCHAR(20),

    related_trades UUID[],
    confidence_score NUMERIC(5, 2),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trades_user_id    ON trades(user_id);
CREATE INDEX IF NOT EXISTS idx_trades_status     ON trades(status);
CREATE INDEX IF NOT EXISTS idx_trades_entry_time ON trades(entry_time);
CREATE INDEX IF NOT EXISTS idx_insights_user_id  ON insights(user_id);
CREATE INDEX IF NOT EXISTS idx_users_email       ON users(email);
