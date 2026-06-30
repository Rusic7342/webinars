-- itscontentflow — reminder helper functions
-- Run in Supabase SQL Editor (beyond promts project). Used by n8n WF#2.
-- Idempotently mark a reminder step as sent on a given channel (no double-sends).

create or replace function mark_tg_step(p_lead uuid, p_step text)
returns void
language sql
security definer
set search_path = public
as $$
  update webinar_leads
     set steps_sent = (select array(select distinct unnest(coalesce(steps_sent, '{}') || array[p_step]))),
         tg_sent    = (select array(select distinct unnest(coalesce(tg_sent,    '{}') || array[p_step])))
   where id = p_lead;
$$;

create or replace function mark_email_step(p_lead uuid, p_step text)
returns void
language sql
security definer
set search_path = public
as $$
  update webinar_leads
     set steps_sent = (select array(select distinct unnest(coalesce(steps_sent,  '{}') || array[p_step]))),
         email_sent = (select array(select distinct unnest(coalesce(email_sent,  '{}') || array[p_step])))
   where id = p_lead;
$$;

revoke all on function mark_tg_step(uuid, text)    from anon;
revoke all on function mark_email_step(uuid, text) from anon;
grant execute on function mark_tg_step(uuid, text)    to service_role;
grant execute on function mark_email_step(uuid, text) to service_role;
