import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const client = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });

  const url = new URL(req.url);
  const since = url.searchParams.get("since") ?? "1970-01-01T00:00:00Z";
  const jwt = req.headers.get("authorization")?.replace("Bearer ", "");

  if (!jwt) return new Response("Unauthorized", { status: 401 });

  const { data: u, error: ue } = await client.auth.getUser(jwt);
  if (ue || !u?.user) return new Response("Unauthorized", { status: 401 });

  const { data, error } = await client.rpc("get_changes", { u_id: u.user.id, since });
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 400 });

  return new Response(JSON.stringify({ tables: data, serverClock: new Date().toISOString() }), {
    headers: { "content-type": "application/json" },
  });
});
