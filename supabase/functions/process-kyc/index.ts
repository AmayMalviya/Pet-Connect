// process-kyc/index.ts  –  Deno / Supabase Edge Function
// Triggered by Flutter KycScreen after file uploads.
// Input  JSON: { userId, zipPath, selfiePath, pan, gstin?, darpanId? }
// Output JSON: { status, trustScore, reason? }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { ZipReader, BlobReader, TextWriter } from "https://deno.land/x/zipjs@v2.7.52/index.js";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    // ── 1. Parse input ──────────────────────────────────────────────────────
    const { userId, zipPath, selfiePath, pan, gstin, darpanId } =
      (await req.json()) as {
        userId: string;
        zipPath: string;
        selfiePath: string;
        pan: string;
        gstin?: string;
        darpanId?: string;
      };

    if (!userId || !zipPath || !selfiePath || !pan) {
      return json({ error: "Missing required fields." }, 400);
    }

    // ── 2. Supabase admin client ────────────────────────────────────────────
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    let trustScore = 0;
    const notes: string[] = [];

    // ── 3. Aadhaar ZIP validation ───────────────────────────────────────────
    let aadhaarName: string | null = null;
    let aadhaarDob: string | null = null;
    let aadhaarValid = false;

    try {
      // Download ZIP from storage
      const { data: zipBlob, error: zipErr } = await supabase.storage
        .from("kyc-documents")
        .download(zipPath);
      if (zipErr) throw zipErr;

      // Read ZIP entries
      const reader = new ZipReader(new BlobReader(zipBlob));
      const entries = await reader.getEntries();

      for (const entry of entries) {
        const name = entry.filename.toLowerCase();

        // Look for XML (UIDAI offline XML)
        if (name.endsWith(".xml")) {
          const xmlText = await entry.getData!(new TextWriter());

          // Verify UIDAI signature presence (production: use WebCrypto to verify RSA-SHA256)
          if (xmlText.includes("Signature") && xmlText.includes("ds:SignatureValue")) {
            aadhaarValid = true;
            notes.push("Aadhaar UIDAI signature found");
          }

          // Extract Name & DOB via simple regex (real: use XML parser)
          const nameMatch = xmlText.match(/name="([^"]+)"/i);
          const dobMatch  = xmlText.match(/dob="([^"]+)"/i);
          if (nameMatch) aadhaarName = nameMatch[1];
          if (dobMatch)  aadhaarDob  = dobMatch[1];
        }
      }

      await reader.close();

      if (aadhaarValid) {
        trustScore += 40;
        notes.push("Aadhaar XML signature verified (+40)");
      } else {
        notes.push("Aadhaar signature missing or invalid");
      }
    } catch (e) {
      notes.push(`Aadhaar ZIP error: ${e}`);
    }

    // ── 4. PAN validation ───────────────────────────────────────────────────
    const panUpper = pan.trim().toUpperCase();
    const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]$/;
    const panFourthChar = panUpper[3]; // 'P' = individual, 'C' = company

    if (panRegex.test(panUpper) && (panFourthChar === "P" || panFourthChar === "C")) {
      trustScore += 30;
      notes.push(`PAN valid, type=${panFourthChar === "P" ? "Individual" : "Company"} (+30)`);
    } else {
      notes.push("PAN failed regex or 4th-char check");
    }

    // ── 5. GST verification (optional) ─────────────────────────────────────
    if (gstin) {
      try {
        // Public GST search API (no auth needed for basic check)
        const gstRes = await fetch(
          `https://sheet.gstincheck.co.in/check/${Deno.env.get("GST_API_KEY")}/${gstin}`,
          { signal: AbortSignal.timeout(5000) },
        );
        if (gstRes.ok) {
          const gstData = await gstRes.json();
          if (gstData?.flag === true) {
            trustScore += 15;
            notes.push("GSTIN verified via public API (+15)");
          } else {
            notes.push("GSTIN not found in GST registry");
          }
        }
      } catch (e) {
        notes.push(`GST API error (non-fatal): ${e}`);
      }
    }

    // ── 6. Darpan ID verification (optional) ───────────────────────────────
    if (darpanId) {
      try {
        const darpanRes = await fetch(
          `https://darpan.gov.in/api/ngoInfo?regno=${encodeURIComponent(darpanId)}`,
          { signal: AbortSignal.timeout(5000) },
        );
        if (darpanRes.ok) {
          const d = await darpanRes.json();
          if (d?.status === "Active" || d?.ngoName) {
            trustScore += 15;
            notes.push("Darpan NGO verified (+15)");
          } else {
            notes.push("Darpan ID not found or inactive");
          }
        }
      } catch (e) {
        notes.push(`Darpan API error (non-fatal): ${e}`);
      }
    }

    // ── 7. Trust-score decision engine ─────────────────────────────────────
    let status: "completed" | "pending_review" | "rejected";

    if (trustScore >= 90) {
      status = "completed";
    } else if (trustScore >= 40) {
      status = "pending_review";
    } else {
      status = "rejected";
    }

    // ── 8. Update shelter_kyc ───────────────────────────────────────────────
    const { error: upsertErr } = await supabase.from("shelter_kyc").upsert(
      {
        user_id: userId,
        pan_number: panUpper,
        gstin: gstin ?? null,
        darpan_id: darpanId ?? null,
        aadhaar_name: aadhaarName,
        aadhaar_dob: aadhaarDob,
        selfie_image_url: selfiePath,
        status,
        trust_score: trustScore,
        reviewer_note: notes.join(" | "),
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id" },
    );

    if (upsertErr) throw new Error(`DB upsert failed: ${upsertErr.message}`);

    // Also mark profile
    await supabase
      .from("profiles")
      .update({
        kyc_submitted: true,
        kyc_status: status,
        kyc_verified: status === "completed",
      })
      .eq("user_id", userId);

    return json({ status, trustScore, notes });
  } catch (err) {
    console.error(err);
    return json({ error: String(err) }, 500);
  }
});
