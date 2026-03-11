import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { RekognitionClient, CompareFacesCommand } from "npm:@aws-sdk/client-rekognition";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.31.0";

console.log("Face verification function booting up...");

serve(async (req) => {
  // This is needed if you're planning to invoke your function from a browser.
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" } });
  }

  try {
    const { aadhaar_image_url, selfie_image_url, user_id } = await req.json();

    if (!aadhaar_image_url || !selfie_image_url || !user_id) {
      return new Response(JSON.stringify({ error: "Missing aadhaar_image_url, selfie_image_url, or user_id" }), {
        headers: { "Content-Type": "application/json" },
        status: 400,
      });
    }

    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}` } } }
    );

    // Download images from Supabase Storage
    const { data: idPhotoData, error: idPhotoError } = await supabase.storage
      .from("user-images") // Assuming your bucket is named 'user-images'
      .download(idPhotoPath);

    if (idPhotoError) throw idPhotoError;

    const { data: selfieData, error: selfieError } = await supabase.storage
      .from("user-images") // Assuming your bucket is named 'user-images'
      .download(selfiePath);

    if (selfieError) throw selfieError;

    // Initialize Rekognition client
    const rekognition = new RekognitionClient({
      region: Deno.env.get("AWS_REGION")!,
      credentials: {
        accessKeyId: Deno.env.get("AWS_ACCESS_KEY_ID")!,
        secretAccessKey: Deno.env.get("AWS_SECRET_ACCESS_KEY")!,
      },
    });

    // Convert blobs to Uint8Array
    const idPhotoBytes = new Uint8Array(await idPhotoData.arrayBuffer());
    const selfieBytes = new Uint8Array(await selfieData.arrayBuffer());

    // Prepare and send the command to Rekognition
    const command = new CompareFacesCommand({
      SourceImage: { Bytes: idPhotoBytes },
      TargetImage: { Bytes: selfieBytes },
      SimilarityThreshold: 90, // You can adjust this threshold
    });

    const response = await rekognition.send(command);

    let isVerified = false;
    if (response.FaceMatches && response.FaceMatches.length > 0) {
      const bestMatch = response.FaceMatches.reduce((prev, current) =>
        (prev.Similarity ?? 0) > (current.Similarity ?? 0) ? prev : current
      );

      if (bestMatch.Similarity && bestMatch.Similarity >= 90) {
        isVerified = true;
      }
    }

    if (isVerified) {
      // Update the user's profile in the 'profiles' table
      const { error: updateError } = await supabase
        .from("profiles")
        .update({ is_verified: true })
        .eq("id", userId);

      if (updateError) {
        throw new Error(`Error updating user profile: ${updateError.message}`);
      }

      return new Response(JSON.stringify({ success: true, message: "Verification successful." }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      });
    } else {
      return new Response(JSON.stringify({ success: false, message: "Verification failed. Faces do not match." }), {
        headers: { "Content-Type": "application/json" },
        status: 400,
      });
    }
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});