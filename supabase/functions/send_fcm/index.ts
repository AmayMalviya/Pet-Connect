// supabase/functions/send_fcm/index.ts

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// ✅ Get Firebase Server Key securely from environment. Set the env var
// `FIREBASE_SERVER_KEY` when deploying this function (do NOT commit keys).
const FIREBASE_SERVER_KEY = Deno.env.get("FIREBASE_SERVER_KEY");

if (!FIREBASE_SERVER_KEY) {
  console.error('FIREBASE_SERVER_KEY is not set in the environment');
}

serve(async (req) => {
  try {
    const { token, title, body, data } = await req.json();

    if (!token || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400 }
      );
    }

    const payload = {
      to: token,
      notification: {
        title,
        body,
        sound: "default",
      },
      data: data || {},
    };

    const res = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `key=${FIREBASE_SERVER_KEY}`,
      },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const error = await res.text();
      console.error("Error sending FCM:", error);
      return new Response(
        JSON.stringify({ success: false, error }),
        { status: 500 }
      );
    }

    const responseData = await res.json();
    return new Response(JSON.stringify({ success: true, responseData }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({ success: false, error: err.toString() }),
      { status: 500 }
    );
  }
});
