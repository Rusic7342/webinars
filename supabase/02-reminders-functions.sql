-- itscontentflow — reminder helper function
-- Run once in: Supabase SQL Editor (beyond promts project).
-- Used by n8n Workflow #2 to mark a reminder step as sent, idempotently.

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

-- service_role (used by n8n) may call it; anon may not.
revoke all on function mark_tg_step(uuid, text) from anon;
grant execute on function mark_tg_step(uuid, text) to service_role;
