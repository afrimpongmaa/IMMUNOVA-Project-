// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(res: unknown, status = 200) {
  return new Response(JSON.stringify(res), {
    status,
    headers: {
      "content-type": "application/json",
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "GET,POST,OPTIONS",
      "access-control-allow-headers": "authorization, content-type",
    },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return json({}, 200);
  if (req.method !== "POST" && req.method !== "GET") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
  const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const client = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const url = new URL(req.url);
  const body = await req.json().catch(() => ({}));
  const patientIdFromBody = (body as any)?.patient_id as string | undefined;
  const patientIdFromQuery = url.searchParams.get("patient_id") ?? undefined;
  const patientId = patientIdFromBody || patientIdFromQuery || undefined;

  // Normalize to current date (UTC) in YYYY-MM-DD
  const todayIso = new Date().toISOString().split("T")[0];

  // If called by an authenticated user: update only their patients (and optional patient_id)
  const authHeader = req.headers.get("authorization");
  const jwt = authHeader?.replace(/^Bearer\s+/i, "");
  let updated = 0;

  try {
    if (jwt) {
      const { data: u, error: ue } = await client.auth.getUser(jwt);
      if (ue || !u?.user) return json({ ok: false, error: "Unauthorized" }, 401);

      // Get this doctor’s patient_ids
      const { data: patients, error: pe } = await client
        .from("patient_records")
        .select("patient_id")
        .eq("doc_id", u.user.id);

      if (pe) return json({ ok: false, error: pe.message }, 500);

      const patientIds = (patients ?? []).map((p: any) => p.patient_id) as string[];
      if (patientIds.length === 0) return json({ ok: true, updated: 0 });

  // Build update
      let q = client
        .from("immunization_records")
        .update({ status: "overdue" })
        .lt("date_due", todayIso)
        .eq("status", "pending")
        .in("patient_id", patientIds);

      if (patientId) {
        q = q.eq("patient_id", patientId);
      }

      const { error: ue2 } = await q;
      if (ue2) return json({ ok: false, error: ue2.message }, 500);

      // Create notifications:
      // 1) Critical: all overdue records (were pending and due < today)
      // 2) Mild: all pending records due today

      // Get affected overdue patient_ids (select after update)
      const { data: overdueRows, error: orErr } = await client
        .from('immunization_records')
        .select('patient_id')
        .lt('date_due', todayIso)
        .eq('status', 'overdue')
        .in('patient_id', patientIds);
      if (orErr) return json({ ok: false, error: orErr.message }, 500);

      const overdueSet = new Set<string>();
      for (const r of overdueRows ?? []) {
        if (r?.patient_id) overdueSet.add(r.patient_id as string);
      }

      // Mild notifications for pending due today
      const { data: pendingToday, error: ptErr } = await client
        .from('immunization_records')
        .select('patient_id')
        .eq('status', 'pending')
        .eq('date_due', todayIso)
        .in('patient_id', patientIds);
      if (ptErr) return json({ ok: false, error: ptErr.message }, 500);

      const pendingSet = new Set<string>();
      for (const r of pendingToday ?? []) {
        if (r?.patient_id) pendingSet.add(r.patient_id as string);
      }

      const inserts: any[] = [];
      for (const pid of overdueSet) {
        inserts.push({
          user_id: u.user.id,
          patient_id: pid,
          severity: 'critical',
          content: `Patient ${pid} has overdue immunization tasks.`,
        });
      }
      for (const pid of pendingSet) {
        inserts.push({
          user_id: u.user.id,
          patient_id: pid,
          severity: 'mild',
          content: `Patient ${pid} has immunization tasks due today.`,
        });
      }

      if (inserts.length > 0) {
        const { error: nErr } = await client.from('notifications').insert(inserts);
        if (nErr) return json({ ok: false, error: nErr.message }, 500);
      }

      return json({ ok: true, updated, notifications: inserts.length });
    }

    // Scheduled/global run (service role): flip all pending that are behind today
    const { error } = await client
      .from("immunization_records")
      .update({ status: "overdue" })
      .lt("date_due", todayIso)
      .eq("status", "pending");

    if (error) return json({ ok: false, error: error.message }, 500);

    // Global notifications (service role): gather patient_ids then map to doc_id
    // 1) Overdue (critical)
    const { data: overduePidRows, error: ogErr } = await client
      .from('immunization_records')
      .select('patient_id')
      .lt('date_due', todayIso)
      .eq('status', 'overdue');
    if (ogErr) return json({ ok: false, error: ogErr.message }, 500);

    // 2) Pending today (mild)
    const { data: pendingPidRows, error: pgErr } = await client
      .from('immunization_records')
      .select('patient_id')
      .eq('status', 'pending')
      .eq('date_due', todayIso);
    if (pgErr) return json({ ok: false, error: pgErr.message }, 500);

    const overduePidSet = new Set<string>();
    for (const r of overduePidRows ?? []) {
      if (r?.patient_id) overduePidSet.add(r.patient_id as string);
    }
    const pendingPidSet = new Set<string>();
    for (const r of pendingPidRows ?? []) {
      if (r?.patient_id) pendingPidSet.add(r.patient_id as string);
    }

    // Map pids to doc_id
    const allPids = Array.from(new Set([...overduePidSet, ...pendingPidSet]));
    let docMap = new Map<string, string>(); // patient_id -> doc_id
    if (allPids.length > 0) {
      const { data: mapRows, error: mapErr } = await client
        .from('patient_records')
        .select('patient_id, doc_id')
        .in('patient_id', allPids);
      if (mapErr) return json({ ok: false, error: mapErr.message }, 500);
      for (const m of mapRows ?? []) {
        if (m?.patient_id && m?.doc_id) {
          docMap.set(m.patient_id as string, m.doc_id as string);
        }
      }
    }

    const notifRows: any[] = [];
    for (const pid of overduePidSet) {
      const doc = docMap.get(pid);
      if (doc) {
        notifRows.push({
          user_id: doc,
          patient_id: pid,
          severity: 'critical',
          content: `Patient ${pid} has overdue immunization tasks.`,
        });
      }
    }
    for (const pid of pendingPidSet) {
      const doc = docMap.get(pid);
      if (doc) {
        notifRows.push({
          user_id: doc,
          patient_id: pid,
          severity: 'mild',
          content: `Patient ${pid} has immunization tasks due today.`,
        });
      }
    }

    if (notifRows.length > 0) {
      const { error: nErr } = await client.from('notifications').insert(notifRows);
      if (nErr) return json({ ok: false, error: nErr.message }, 500);
    }

    return json({ ok: true, updated, notifications: notifRows.length });
  } catch (e: any) {
    return json({ ok: false, error: String(e?.message ?? e) }, 500);
  }
});

/*
Scheduling

If you see "unknown flag: --cron", your Supabase CLI is outdated.

1) Check and update CLI
   - Check: supabase --version
   - Update (Windows):
       supabase update
     or reinstall via your package manager:
       scoop update supabase    (if installed with Scoop)
       choco upgrade supabase   (if installed with Chocolatey)
   - Update (macOS/Homebrew):
       brew upgrade supabase/tap/supabase
   - Then re-check: supabase --version

2) Deploy the function
   supabase functions deploy mark-overdue

3) Create the schedule (daily 02:00 UTC)
   supabase functions schedule create mark-overdue --cron "0 2 * * *" --method GET

Alternative (no CLI): Dashboard
- Go to Supabase Dashboard → Edge Functions → Schedules → New schedule
- Select function: mark-overdue
- Method: GET
- Cron: 0 2 * * *
- Save

Notes:
- GET/POST both supported. From the app, call with:
    await Supabase.instance.client.functions.invoke('mark-overdue', method: HttpMethod.post);
- To scope to one patient from the app:
    await Supabase.instance.client.functions.invoke('mark-overdue', method: HttpMethod.post, body: { patient_id: '<uuid>' });
*/
