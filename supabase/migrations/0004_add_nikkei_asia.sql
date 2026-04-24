-- Add Nikkei Asia as a selectable source.
--
-- The backend now fetches from nikkei_asia (via Google News proxy since the
-- official feed omits publish dates). Update the user_preferences defaults
-- so new users see it by default, and backfill existing users.
--
-- Run in Supabase SQL Editor.

alter table public.user_preferences
    alter column enabled_sources set default
    array['bloomberg','reuters','ft','cnbc','yahoo','marketwatch','nikkei_asia'];

update public.user_preferences
    set enabled_sources = array_append(enabled_sources, 'nikkei_asia')
    where not ('nikkei_asia' = any(enabled_sources));
