# NewsApp — Morning Financial News Digest

매일 아침 글로벌 금융 뉴스 주요 3–5건을 요약해 알림으로 보내주는 모바일 앱 + Telegram 봇. 한국 증권/금융인 타깃.

## Architecture

```
GitHub Actions cron (05:30 KST daily)
  → fetch RSS from 6 sources
  → cluster + rank top 3-5 stories
  → summarize via pluggable LLM (Anthropic / Groq / GLM)
  → upsert to Supabase
          │
          ├── Flutter app (Android first, iOS later)
          │     - FCM push at user's notify_time
          │     - Tap → original article link
          │
          └── Telegram bot
                - Hourly fan-out to registered chat_ids
```

## Directory Layout

| Folder | Purpose |
|---|---|
| `backend/` | Python pipeline: RSS fetch, summarize, upsert to Supabase. Runs in GitHub Actions. |
| `supabase/migrations/` | Postgres schema migrations |
| `app/` | Flutter mobile app (Android + iOS) — Phase 2 |
| `bot/` | Python Telegram bot — Phase 3 |
| `.github/workflows/` | GitHub Actions cron workflows |

## Content Licensing Policy

**Conservative until revenue supports licensing (Reuters Connect / Bloomberg / FT Syndication).**

| Source | Policy |
|---|---|
| Yahoo Finance, MarketWatch, CNBC | Full AI summary allowed (RSS-friendly) |
| Reuters | Short AI summary, link-prominent |
| Bloomberg, Financial Times | **Headline + link only, no summary** (aggressive rights holders) |

## LLM Provider Options

Selected via `LLM_PROVIDER` env var. Abstraction in `backend/summarizer/`.

| Provider | Model | Cost | Quality |
|---|---|---|---|
| `anthropic` | Claude Haiku 4.5 | ~$1/1M input, $5/1M output (~$0.50/month for daily digest) | Highest |
| `groq` | Llama 3.3 70B | Free tier: 14,400 req/day | High |
| `glm` | GLM-4-Flash | Free | Decent, OK for Korean |

## Setup

### 1. Accounts needed (all free to start)

- [ ] Supabase project ([supabase.com](https://supabase.com))
- [ ] One LLM provider API key:
  - Anthropic: [console.anthropic.com](https://console.anthropic.com)
  - Groq: [console.groq.com](https://console.groq.com) (free)
  - GLM (Z.ai): [bigmodel.cn](https://open.bigmodel.cn/) (free tier)
- [ ] Telegram bot token from [@BotFather](https://t.me/BotFather) (Phase 3)

### 2. Supabase

1. Create new project at supabase.com
2. SQL Editor → run `supabase/migrations/0001_initial_schema.sql`
3. Project Settings → API → copy `URL` and `service_role` key

### 3. Backend environment

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate   # Windows
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your keys
python main.py           # dry-run locally
```

### 4. GitHub Actions secrets

Settings → Secrets → Actions, add:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_KEY`
- `LLM_PROVIDER` (anthropic / groq / glm)
- `ANTHROPIC_API_KEY` / `GROQ_API_KEY` / `GLM_API_KEY` (whichever you chose)

The workflow in `.github/workflows/daily-digest.yml` runs at 20:30 UTC daily (= 05:30 KST).

### 5. Flutter app (Phase 2 — TBD)

See `app/README.md` when scaffolded.

### 6. Telegram bot (Phase 3 — TBD)

See `bot/README.md` when scaffolded.

## Dev Status

- [x] Project structure + licensing policy
- [ ] Supabase schema
- [ ] Backend pipeline (RSS + LLM abstraction + Supabase upsert)
- [ ] GitHub Actions cron
- [ ] Flutter app (Android)
- [ ] Telegram bot
- [ ] Flutter app (iOS)
- [ ] AdMob integration
- [ ] Play Store release
