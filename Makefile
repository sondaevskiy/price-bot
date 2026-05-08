.PHONY: up down build logs shell migrate cert

# ─── Запуск ───────────────────────────────────────────────────
up:
	docker compose up -d

up-build:
	docker compose up -d --build

down:
	docker compose down

restart:
	docker compose restart

# ─── Логи ─────────────────────────────────────────────────────
logs:
	docker compose logs -f --tail=100

logs-bot:
	docker compose logs -f bot --tail=100

logs-worker:
	docker compose logs -f worker --tail=100

logs-api:
	docker compose logs -f api --tail=100

# ─── Разработка ───────────────────────────────────────────────
build:
	docker compose build

shell-api:
	docker compose exec api bash

shell-db:
	docker compose exec postgres psql -U pricebot -d pricebot

# ─── БД ───────────────────────────────────────────────────────
migrate:
	docker compose exec api alembic upgrade head

migrate-create:
	docker compose exec api alembic revision --autogenerate -m "$(name)"

db-backup:
	docker compose exec postgres pg_dump -U pricebot pricebot > backup_$(shell date +%Y%m%d_%H%M%S).sql

# ─── SSL (Let's Encrypt) ──────────────────────────────────────
cert:
	docker run --rm \
	  -v $(PWD)/nginx/certs:/etc/letsencrypt \
	  -v $(PWD)/nginx/certbot:/var/www/certbot \
	  certbot/certbot certonly \
	  --webroot --webroot-path=/var/www/certbot \
	  -d yourdomain.com \
	  --email your@email.com \
	  --agree-tos --no-eff-email

cert-renew:
	docker run --rm \
	  -v $(PWD)/nginx/certs:/etc/letsencrypt \
	  -v $(PWD)/nginx/certbot:/var/www/certbot \
	  certbot/certbot renew

# ─── Мониторинг ───────────────────────────────────────────────
stats:
	docker compose stats

ps:
	docker compose ps
