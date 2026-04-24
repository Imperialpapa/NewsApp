-- Fix articles unique constraint: rank is per-source, not per-digest.
-- Pipeline produces up to 5 articles per source (~25 rows/digest), and the UI
-- groups by source. The original (digest_id, rank) unique index rejected
-- rank=1 collisions across different sources — this migration makes the
-- uniqueness per (digest_id, source, rank).
--
-- Run in Supabase SQL Editor.

drop index if exists public.articles_digest_rank_uniq;
drop index if exists public.articles_digest_idx;

create index articles_digest_idx
    on public.articles (digest_id, source, rank);

create unique index articles_digest_source_rank_uniq
    on public.articles (digest_id, source, rank);
