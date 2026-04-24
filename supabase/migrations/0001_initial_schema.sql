-- NewsApp initial schema
-- Run in Supabase SQL Editor

-- Digests: one row per day. Articles belong to a digest.
create table public.digests (
    id uuid primary key default gen_random_uuid(),
    digest_date date not null unique,
    generated_at timestamptz not null default now(),
    provider text not null,           -- llm provider used (anthropic/groq/glm)
    article_count int not null default 0
);

create index digests_date_idx on public.digests (digest_date desc);

-- Articles: top 3-5 stories per digest. Bloomberg/FT have null summaries (link-only).
create table public.articles (
    id uuid primary key default gen_random_uuid(),
    digest_id uuid not null references public.digests(id) on delete cascade,
    source text not null,             -- 'bloomberg' | 'reuters' | 'ft' | 'cnbc' | 'yahoo' | 'marketwatch'
    headline text not null,
    original_url text not null,
    published_at timestamptz,
    summary_en text,                  -- null for bloomberg/ft (headline-only policy)
    summary_ko text,                  -- null for bloomberg/ft, else Korean summary
    rank int not null,                -- 1..5
    created_at timestamptz not null default now()
);

create index articles_digest_idx on public.articles (digest_id, rank);
create unique index articles_digest_rank_uniq on public.articles (digest_id, rank);

-- User preferences. FK to auth.users (Supabase Auth).
create table public.user_preferences (
    user_id uuid primary key references auth.users(id) on delete cascade,
    notify_time time not null default '09:00:00',  -- local time (KST assumed for MVP)
    language text not null default 'ko',           -- 'ko' | 'en'
    enabled boolean not null default true,
    telegram_chat_id bigint,                       -- null if not linked
    fcm_token text,                                -- null if not registered
    enabled_sources text[] not null default array['bloomberg','reuters','ft','cnbc','yahoo','marketwatch'],
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index user_prefs_notify_time_idx on public.user_preferences (notify_time) where enabled = true;
create index user_prefs_telegram_idx on public.user_preferences (telegram_chat_id) where telegram_chat_id is not null;

-- Update trigger
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger user_prefs_updated_at
    before update on public.user_preferences
    for each row execute function public.touch_updated_at();

-- RLS: digests + articles are public-read (authenticated users only).
-- user_preferences: owner-only.
alter table public.digests enable row level security;
alter table public.articles enable row level security;
alter table public.user_preferences enable row level security;

create policy "digests: authenticated read" on public.digests
    for select using (auth.role() = 'authenticated');

create policy "articles: authenticated read" on public.articles
    for select using (auth.role() = 'authenticated');

create policy "prefs: owner read" on public.user_preferences
    for select using (auth.uid() = user_id);

create policy "prefs: owner insert" on public.user_preferences
    for insert with check (auth.uid() = user_id);

create policy "prefs: owner update" on public.user_preferences
    for update using (auth.uid() = user_id);

-- Auto-create user_preferences row when a new auth.users row is inserted.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
    insert into public.user_preferences (user_id) values (new.id) on conflict do nothing;
    return new;
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();
