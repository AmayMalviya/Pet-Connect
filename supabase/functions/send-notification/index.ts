import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.7/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Helper function to get an OAuth2 access token from Google
async function getAccessToken(serviceAccount: any) {
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/cloud-platform",
    aud: "https://oauth2.googleapis.com/token",
    exp: getNumericDate(3600),
    iat: getNumericDate(0),
  };

  const jwt = await create(header, payload, serviceAccount.private_key);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\${jwt}`,
  });

  const tokens = await response.json();
  return tokens.access_token;
}

serve(async (req) => {
  try {
    const { record } = await req.json();
    const userId = record.user_id;

    if (!userId) throw new Error("user_id is missing");

    // 1. Get the Service Account key from secrets
    const serviceAccountJson = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_KEY");
    if (!serviceAccountJson) throw new Error("GOOGLE_SERVICE_ACCOUNT_KEY is not set");
    const serviceAccount = JSON.parse(serviceAccountJson);

    // 2. Fetch the user's FCM token from the 'profiles' table
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? ""
    );

    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('fcm_token')
      .eq('user_id', userId)
      .single();

    if (profileError) throw new Error(profileError.message);
    const fcmToken = profile?.fcm_token;
    if (!fcmToken) throw new Error("FCM token not found for the user.");

    // 3. Get the OAuth2 access token
    const accessToken = await getAccessToken(serviceAccount);

    // 4. Construct the v1 API message payload
    const message = {
      message: {
        token: fcmToken,
        notification: {
          title: `New Event: \${record.title}`,
          body: record.description || "You have a new event in your calendar.",
        },
        data: {
          screen: "/health-details",
          petId: record.pet_id,
        },
      },
    };

    // 5. Send the request to the FCM v1 API
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/\${serviceAccount.project_id}/messages:send`;
    const response = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer \${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`FCM v1 request failed: \${response.status} \${errorBody}`);
    }

    console.log("Successfully sent FCM v1 notification.");

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Error sending FCM notification:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});