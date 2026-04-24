-- Add per-user collapsed-source preference for the digest list UI.
-- A source key in this array means the user has collapsed that section on
-- the digest screen; the articles stay enabled, just hidden behind a header.
--
-- Run in Supabase SQL Editor.

alter table public.user_preferences
    add column collapsed_sources text[] not null default '{}';
