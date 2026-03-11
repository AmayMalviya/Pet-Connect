import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.7/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Helper function to import a PEM-formatted RSA private key
async function importPrivateKey(pemKey) {
  const pem = pemKey.replace(/\\n/g, "").replace("-----BEGIN PRIVATE KEY-----", "").replace("-----END PRIVATE KEY-----", "");
  const binaryDer = new Uint8Array(atob(pem).split("").map(c => c.charCodeAt(0)));
  return await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    true,
    ["sign"]
  );
}

// Helper function to get an OAuth2 access token from Google
async function getAccessToken(serviceAccount) {
  const header = {
    alg: "RS256",
    typ: "JWT"
  };
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/cloud-platform",
    aud: "https://oauth2.googleapis.com/token",
    exp: getNumericDate(3600),
    iat: getNumericDate(0)
  };

  // Import the private key before using it
  const privateKey = await importPrivateKey(serviceAccount.private_key);
  const jwt = await create(header, payload, privateKey);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`
  });
  const tokens = await response.json();
  if (!tokens.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokens)}`);
  }
  return tokens.access_token;
}
a
    const userId = record.user_id;
    if (!userId) throw new Error("user_id is missing from the event record");

    // 1. Get the Service Account key from secrets
    const serviceAccountJson = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_KEY");
    if (!serviceAccountJson) throw new Error("GOOGLE_SERVICE_ACCOUNT_KEY is not set");
    const serviceAccount = JSON.parse(serviceAccountJson);

    // 2. Create a Supabase admin client
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 3. Fetch the user's FCM token
    const { data: profile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("fcm_token")
      .eq("user_id", userId)
      .single();

    if (profileError) throw new Error(`Error fetching profile: ${profileError.message}`);

    const fcmToken = profile?.fcm_token;
    if (!fcmToken) {
      console.warn(`FCM token not found for user ${userId}. Skipping notification.`);
      return new Response(JSON.stringify({ success: true, message: "FCM token not found." }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // 4. Get the OAuth2 access token
    const accessToken = await getAccessToken(serviceAccount);

    // 5. Construct the FCM message
    const message = {
      message: {
        token: fcmToken,
        notification: {
          title: `New Event: ${record.title}`,
          body: record.description || "You have a new event in your calendar."
        },
        data: { screen: "/health-details", petId: record.pet_id }
      }
    };

    // 6. Send the request to FCM
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
    const response = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(message)
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`FCM request failed: ${response.status} ${errorBody}`);
    }

    console.log("Successfully sent FCM notification.");
    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Error sending FCM notification:", error.message, error.stack);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});