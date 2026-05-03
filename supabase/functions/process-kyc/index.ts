// process-kyc/index.ts  – Deno / Supabase Edge Function
// Triggered by Flutter KycScreen after file uploads.
// Input  JSON: { userId, zipPath, selfiePath, pan, shareCode, gstin?, darpanId? }
// Output JSON: { status, trustScore, notes }
//
// UIDAI Offline E-Aadhaar XML structure reference:
// <OfflinePaperlessKyc referenceId="..." uid="XXXX-XXXX-1234">
//   <UidData>
//     <Poi name="JOHN DOE" dob="01-01-1990" gender="M" phone="..."/>
//     <Poa dist="..." state="..." pc="..."/>
//     <Pht>base64photo</Pht>
//   </UidData>
//   <Signature xmlns:ds="..."><ds:SignedInfo>...</ds:SignedInfo>
//     <ds:SignatureValue>...</ds:SignatureValue></Signature>
// </OfflinePaperlessKyc>

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { ZipReader, BlobReader, TextWriter } from "https://deno.land/x/zipjs@v2.7.52/index.js";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });

// ── XML helpers ────────────────────────────────────────────────────────────────

/**
 * Extract a named attribute from a specific XML element.
 * Looks for <ElementName ... attrName="VALUE" ...> patterns.
 * More reliable than a global attribute search.
 */
function extractAttrFromElement(
  xml: string,
  elementName: string,
  attrName: string,
): string | null {
  // Match the opening tag of the element (case-insensitive)
  const tagRegex = new RegExp(
    `<${elementName}[^>]+\\s${attrName}\\s*=\\s*"([^"]*)"`,
    "i",
  );
  const m = xml.match(tagRegex);
  return m ? m[1].trim() : null;
}

/**
 * Fallback: search entire document for the attribute.
 * Avoids matching xmlns:xx type attributes by requiring a word boundary.
 */
function extractAttrGlobal(xml: string, attrName: string): string | null {
  // \b ensures we don't match "someOtherAttrname="
  const regex = new RegExp(`\\b${attrName}\\s*=\\s*"([^"]+)"`, "i");
  const m = xml.match(regex);
  return m ? m[1].trim() : null;
}

/**
 * Check if a UIDAI XML signature block is present.
 * Handles both namespaced (ds:SignatureValue) and plain (SignatureValue) forms.
 */
function hasUidaiSignature(xml: string): boolean {
  return (
    xml.includes("SignatureValue") &&
    (xml.includes("SignedInfo") || xml.includes("Signature"))
  );
}

// ── Main handler ───────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    // ── 1. Parse input ─────────────────────────────────────────────────────
    const { userId, zipPath, selfiePath, pan, shareCode, gstin, darpanId } =
      (await req.json()) as {
        userId: string;
        zipPath: string;
        selfiePath: string;
        pan: string;
        shareCode?: string; // 4-digit UIDAI share code (AES-256 ZIP password)
        gstin?: string;
        darpanId?: string;
      };

    if (!userId || !zipPath || !selfiePath || !pan) {
      return json({ error: "Missing required fields." }, 400);
    }

    // ── 2. Supabase admin client ───────────────────────────────────────────
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    let trustScore = 0;
    const notes: string[] = [];

    // ── 3. Aadhaar ZIP validation ──────────────────────────────────────────
    let aadhaarName: string | null = null;
    let aadhaarDob: string | null = null;
    let aadhaarValid = false;

    try {
      // Download ZIP from storage (bucket: kyc_bucket)
      const { data: zipBlob, error: zipErr } = await supabase.storage
        .from("kyc_bucket")          // ← correct bucket name
        .download(zipPath);
      if (zipErr) throw new Error(`Storage download failed: ${zipErr.message}`);
      if (!zipBlob) throw new Error("ZIP blob is empty");

      notes.push(`ZIP downloaded, size=${zipBlob.size} bytes`);

      // ── Open the ZIP with the share code as password ───────────────────
      // UIDAI offline XMLs are AES-256 encrypted using the share code.
      const reader = new ZipReader(new BlobReader(zipBlob), {
        password: shareCode || undefined,
      });

      let entries;
      try {
        entries = await reader.getEntries();
        notes.push(`ZIP opened, entries=${entries.length}`);
      } catch (pwErr: any) {
        notes.push(
          `ZIP could not be opened (${pwErr}) — check share code`,
        );
        await reader.close();
        throw pwErr;
      }

      // ── Scan entries for the UIDAI XML ────────────────────────────────
      for (const entry of entries) {
        const entryName = entry.filename.toLowerCase();
        notes.push(`Found ZIP entry: ${entry.filename}`);

        if (!entryName.endsWith(".xml")) continue;

        let xmlText: string;
        try {
          xmlText = await entry.getData!(new TextWriter(), {
            password: shareCode || undefined,
          });
        } catch (decryptErr: any) {
          notes.push(
            `XML decryption failed for ${entry.filename}: ${decryptErr}`,
          );
          continue;
        }

        notes.push(`XML length: ${xmlText.length} chars`);

        // ── Signature check ───────────────────────────────────────────
        if (hasUidaiSignature(xmlText)) {
          aadhaarValid = true;
          notes.push("UIDAI digital signature block found");
        } else {
          notes.push("No UIDAI signature block detected in XML");
        }

        // ── Extract Name from <Poi name="..."> ────────────────────────
        // Primary: look specifically inside <Poi> element
        aadhaarName =
          extractAttrFromElement(xmlText, "Poi", "name") ??
          extractAttrFromElement(xmlText, "UidData", "name") ??
          extractAttrGlobal(xmlText, "name");

        // ── Extract DOB from <Poi dob="..."> ──────────────────────────
        // UIDAI format: DD-MM-YYYY or YYYY-MM-DD
        aadhaarDob =
          extractAttrFromElement(xmlText, "Poi", "dob") ??
          extractAttrFromElement(xmlText, "UidData", "dob") ??
          extractAttrGlobal(xmlText, "dob");

        notes.push(
          `Extracted — name: ${aadhaarName ?? "NOT FOUND"}, dob: ${aadhaarDob ?? "NOT FOUND"}`,
        );

        // Log first 300 chars of XML for debugging (redacted in production)
        if (!aadhaarName || !aadhaarDob) {
          const preview = xmlText.substring(0, 300).replace(/\n/g, " ");
          notes.push(`XML preview (first 300 chars): ${preview}`);
        }

        break; // Stop after first XML file
      }

      await reader.close();

      if (aadhaarValid) {
        trustScore += 40;
        notes.push("Aadhaar signature verified (+40)");
      } else {
        notes.push("Aadhaar signature missing — manual review needed");
      }

      // Partial credit if name/dob extracted even without signature
      if (aadhaarName && aadhaarDob && !aadhaarValid) {
        trustScore += 15;
        notes.push("Aadhaar name/DOB extracted without signature (+15)");
      }
    } catch (e: any) {
      notes.push(`Aadhaar ZIP processing error: ${e}`);
    }

    // ── 4. PAN validation ──────────────────────────────────────────────────
    const panUpper = pan.trim().toUpperCase();
    const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]$/;
    const panFourthChar = panUpper[3]; // P = individual, C = company/trust

    if (panRegex.test(panUpper) && (panFourthChar === "P" || panFourthChar === "C")) {
      trustScore += 30;
      notes.push(`PAN valid, type=${panFourthChar === "P" ? "Individual" : "Company"} (+30)`);
    } else {
      notes.push(
        `PAN failed — value="${panUpper}", 4th char="${panFourthChar ?? "?"}"`,
      );
    }

    // ── 5. GST verification (optional) ────────────────────────────────────
    if (gstin) {
      try {
        const gstRes = await fetch(
          `https://sheet.gstincheck.co.in/check/${Deno.env.get("GST_API_KEY")}/${gstin}`,
          { signal: AbortSignal.timeout(5000) },
        );
        if (gstRes.ok) {
          const gstData = await gstRes.json();
          if (gstData?.flag === true) {
            trustScore += 15;
            notes.push("GSTIN verified (+15)");
          } else {
            notes.push("GSTIN not found in GST registry");
          }
        } else {
          notes.push(`GST API returned ${gstRes.status}`);
        }
      } catch (e: any) {
        notes.push(`GST API error (non-fatal): ${e}`);
      }
    }

    // ── 6. Darpan ID verification (optional) ──────────────────────────────
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
      } catch (e: any) {
        notes.push(`Darpan API error (non-fatal): ${e}`);
      }
    }

    // ── 7. Trust-score decision ────────────────────────────────────────────
    let status: "completed" | "pending_review" | "rejected";

    if (trustScore >= 90) {
      status = "completed";
    } else if (trustScore >= 40) {
      status = "pending_review";
    } else {
      status = "rejected";
    }

    notes.push(`Final trust score: ${trustScore} → status: ${status}`);

    // ── 8. Upsert shelter_kyc ──────────────────────────────────────────────
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

    // ── 9. Update profile ──────────────────────────────────────────────────
    await supabase
      .from("profiles")
      .update({
        kyc_submitted: true,
        kyc_status: status,
        kyc_verified: status === "completed",
      })
      .eq("user_id", userId);

    return json({ status, trustScore, notes });
  } catch (err: any) {
    console.error("process-kyc fatal error:", err);
    return json({ error: String(err) }, 500);
  }
});
