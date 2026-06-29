-- itscontentflow — webinar funnel schema
-- Run this in: Supabase Dashboard → SQL Editor → New query → Run.
-- Portable: works in any Supabase project (new free org, or existing).

create extension if not exists "pgcrypto";

-- ============================================================
-- webinars: one row per scheduled live session
-- ============================================================
create table if not exists webinars (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null,          -- e.g. 'launch' (referenced by the landing form)
  title       text not null,
  starts_at   timestamptz not null,          -- ALWAYS store in UTC; render local time per lead
  duration_min int default 60,
  join_url    text,                          -- Zoom / YouTube Live link (kept out of the landing)
  replay_url  text,
  created_at  timestamptz default now()
);

-- ============================================================
-- webinar_leads: one row per registrant
-- ============================================================
create table if not exists webinar_leads (
  id            uuid primary key default gen_random_uuid(),  -- generated client-side; used as Telegram ?start= param
  webinar_slug  text,                         -- which webinar (n8n resolves slug -> webinars.id)
  webinar_id    uuid references webinars(id), -- optional; can be backfilled by n8n
  first_name    text,
  email         text not null,
  timezone      text,                         -- IANA tz auto-captured from the browser, e.g. 'Europe/Berlin'

  -- messenger channels
  tg_chat_id      bigint,                     -- filled when the lead presses Start in the bot
  tg_connected_at timestamptz,
  wa_phone        text,
  wa_consent      boolean not null default false,

  -- progressive profile (enriched after signup via the bot survey)
  level         text,                         -- beginner | practicing | pro
  goal          text,                         -- what they want from the webinar

  -- engagement / scoring (behavioral signals)
  open_count      int not null default 0,
  click_count     int not null default 0,
  calendar_added  boolean not null default false,
  score           int not null default 0,     -- lead "temperature"

  -- delivery state (the cron reminder workflow reads/writes this)
  steps_sent    text[] not null default '{}', -- reminder steps already sent, e.g. {confirm,day_before,hour_before}
  email_sent    text[] not null default '{}', -- per-channel tracking so a partial failure can't double-send
  tg_sent       text[] not null default '{}',
  attended      boolean not null default false,

  source        jsonb,                        -- utm params + referrer
  created_at    timestamptz default now()
);

-- one registration per email per webinar
create unique index if not exists webinar_leads_email_per_webinar
  on webinar_leads (webinar_slug, email);

-- handy lookups for the cron workflow
create index if not exists webinar_leads_slug_idx on webinar_leads (webinar_slug);
create index if not exists webinar_leads_tg_idx   on webinar_leads (tg_chat_id);

-- ============================================================
-- Row Level Security
-- ============================================================
-- The public landing uses the ANON key and may ONLY insert a lead.
-- n8n uses the SERVICE ROLE key, which bypasses RLS for reads/updates/sends.
alter table webinar_leads enable row level security;
alter table webinars      enable row level security;

-- Allow anonymous visitors to register (insert), nothing else.
drop policy if exists "anon can register" on webinar_leads;
create policy "anon can register" on webinar_leads
  for insert to anon
  with check (true);

-- No anon policies on `webinars` → not readable/writable with the anon key.
-- (The landing doesn't read it; n8n reads it via service role.)
