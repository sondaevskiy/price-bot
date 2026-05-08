-- Инициализация БД price-monitoring бота
-- Запускается автоматически при первом старте PostgreSQL контейнера

-- ─── Users ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id           BIGINT PRIMARY KEY,
    username     VARCHAR(64),
    first_name   VARCHAR(64),
    plan         VARCHAR(16)  NOT NULL DEFAULT 'free',
    plan_until   TIMESTAMP,
    ref_by       BIGINT       REFERENCES users(id) ON DELETE SET NULL,
    bonus_slots  INT          NOT NULL DEFAULT 0,
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ─── Tracked items ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tracked_items (
    id           SERIAL PRIMARY KEY,
    user_id      BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    url          TEXT         NOT NULL,
    platform     VARCHAR(16)  NOT NULL,   -- wb | ozon | ym | ali | avito
    external_id  VARCHAR(128),
    title        TEXT,
    image_url    TEXT,
    target_price DECIMAL(12,2),
    last_price   DECIMAL(12,2),
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tracked_items_user
    ON tracked_items(user_id) WHERE is_active = TRUE;

-- ─── Price history ────────────────────────────────────────────
-- Партиционирование по месяцам для производительности
CREATE TABLE IF NOT EXISTS price_history (
    id             BIGSERIAL,
    item_id        INT          NOT NULL REFERENCES tracked_items(id) ON DELETE CASCADE,
    price          DECIMAL(12,2) NOT NULL,
    original_price DECIMAL(12,2),
    in_stock       BOOLEAN,
    seller_rating  DECIMAL(3,2),
    delivery_days  INT,
    checked_at     TIMESTAMP    NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, checked_at)
) PARTITION BY RANGE (checked_at);

-- Создаём партиции на год вперёд (скрипт деплоя должен добавлять новые каждый месяц)
CREATE TABLE IF NOT EXISTS price_history_2025_01
    PARTITION OF price_history FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE IF NOT EXISTS price_history_2025_02
    PARTITION OF price_history FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE IF NOT EXISTS price_history_2025_03
    PARTITION OF price_history FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE IF NOT EXISTS price_history_2025_04
    PARTITION OF price_history FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE IF NOT EXISTS price_history_2025_05
    PARTITION OF price_history FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE IF NOT EXISTS price_history_2025_06
    PARTITION OF price_history FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE IF NOT EXISTS price_history_2025_07
    PARTITION OF price_history FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
CREATE TABLE IF NOT EXISTS price_history_2025_08
    PARTITION OF price_history FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE IF NOT EXISTS price_history_2025_09
    PARTITION OF price_history FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE IF NOT EXISTS price_history_2025_10
    PARTITION OF price_history FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE IF NOT EXISTS price_history_2025_11
    PARTITION OF price_history FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE IF NOT EXISTS price_history_2025_12
    PARTITION OF price_history FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
CREATE TABLE IF NOT EXISTS price_history_2026_01
    PARTITION OF price_history FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE IF NOT EXISTS price_history_2026_02
    PARTITION OF price_history FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE IF NOT EXISTS price_history_2026_03
    PARTITION OF price_history FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE IF NOT EXISTS price_history_2026_04
    PARTITION OF price_history FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE IF NOT EXISTS price_history_2026_05
    PARTITION OF price_history FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE IF NOT EXISTS price_history_2026_06
    PARTITION OF price_history FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

CREATE INDEX IF NOT EXISTS idx_price_history_item
    ON price_history(item_id, checked_at DESC);

-- ─── Subscriptions ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subscriptions (
    id           SERIAL PRIMARY KEY,
    user_id      BIGINT       NOT NULL REFERENCES users(id),
    plan         VARCHAR(16)  NOT NULL,
    amount       DECIMAL(10,2) NOT NULL,
    currency     VARCHAR(4)   NOT NULL DEFAULT 'RUB',
    provider     VARCHAR(16)  NOT NULL,   -- yukassa | tg_stars
    provider_id  VARCHAR(128),
    status       VARCHAR(16)  NOT NULL DEFAULT 'pending',   -- pending | succeeded | canceled
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user
    ON subscriptions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_subscriptions_provider_id
    ON subscriptions(provider_id) WHERE status = 'pending';

-- ─── Products (для умного поиска) ─────────────────────────────
CREATE TABLE IF NOT EXISTS products (
    id              SERIAL PRIMARY KEY,
    normalized_name TEXT         NOT NULL,
    brand           VARCHAR(64),
    category        VARCHAR(64),
    search_query    TEXT,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS product_offers (
    id              SERIAL PRIMARY KEY,
    product_id      INT          NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    platform        VARCHAR(16)  NOT NULL,
    external_id     VARCHAR(128) NOT NULL,
    url             TEXT,
    title           TEXT,
    price           DECIMAL(12,2),
    seller_rating   DECIMAL(3,2),
    reviews_count   INT,
    delivery_days   INT,
    is_official     BOOLEAN      NOT NULL DEFAULT FALSE,
    benefit_score   SMALLINT,
    ai_summary      TEXT,
    updated_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    UNIQUE(platform, external_id)
);

-- ─── Функция автообновления updated_at ────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
