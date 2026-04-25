-- Track whether the user has explicitly chosen a summary language.
-- When false, the app auto-syncs `language` from the device locale on first
-- launch (Korean device → 'ko', otherwise 'en') and flips this flag to true.
-- After that, the user's explicit choice in the settings screen wins.
--
-- Existing rows default to false, so they will go through one round of
-- auto-detection on the next app launch — acceptable for the pre-launch
-- dogfood phase.
--
-- Run in Supabase SQL Editor.

alter table public.user_preferences
    add column language_explicit boolean not null default false;
