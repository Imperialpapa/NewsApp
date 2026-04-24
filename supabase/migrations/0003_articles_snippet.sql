-- Add nullable `snippet` column to articles so we can display the raw RSS
-- description field for sources that are not AI-summarized (Bloomberg, FT).
-- The snippet is the publisher's own teaser as shipped in their RSS feed —
-- redistributing it as-is is standard RSS consumption, unlike LLM-rewritten
-- summaries which are a legal gray zone for those rights holders.
--
-- Run in Supabase SQL Editor.

alter table public.articles
    add column snippet text;
