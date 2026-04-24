-- 0002: per-source articles
-- Previously the digest held a single global top-5; now it holds up to 5 articles
-- per source (~18-30 rows total). rank is now 1..5 WITHIN a source.

drop index if exists public.articles_digest_rank_uniq;
create unique index articles_digest_source_rank_uniq
    on public.articles (digest_id, source, rank);
