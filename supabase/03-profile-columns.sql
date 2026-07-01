-- itscontentflow — profile columns for the Telegram bot survey
-- Run once in Supabase SQL Editor (beyond promts project).
-- level + goal already exist from the initial schema.

alter table webinar_leads
  add column if not exists apply       text,   -- where they'll use it: social | email | web | client
  add column if not exists experience  text,   -- new | mid | veteran
  add column if not exists struggle    text,   -- generic | slow | prompting | voice
  add column if not exists niche       text,   -- coach | creator | ecom | service | freelancer
  add column if not exists rating      text,   -- post-webinar: loved | good | meh
  add column if not exists wants_next  text;   -- post-webinar: yes | no
