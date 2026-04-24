-- Switch default user language from Korean to English.
-- The product pivoted from Korean financial professionals to a global audience,
-- so English is now the expected primary language. Korean remains selectable
-- in the settings screen. Existing rows keep whatever the user already has —
-- only the default for new signups changes.
--
-- Run in Supabase SQL Editor.

alter table public.user_preferences
    alter column language set default 'en';
