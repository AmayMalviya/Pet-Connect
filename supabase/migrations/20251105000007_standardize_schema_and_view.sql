-- Standardize pets and pet_products schema and recreate canonical recommendations view

-- Ensure pet fields exist with defaults
ALTER TABLE pets
  ADD COLUMN IF NOT EXISTS species text,
  ADD COLUMN IF NOT EXISTS breed text,
  ADD COLUMN IF NOT EXISTS allergies text[] DEFAULT '{}'::text[],
  ADD COLUMN IF NOT EXISTS medical_conditions text[] DEFAULT '{}'::text[];

-- Ensure product table and columns exist with consistent names
ALTER TABLE pet_products
  ADD COLUMN IF NOT EXISTS species text,
  ADD COLUMN IF NOT EXISTS allowed_breeds text[],
  ADD COLUMN IF NOT EXISTS ingredients text[],
  ADD COLUMN IF NOT EXISTS contraindications text[],
  ADD COLUMN IF NOT EXISTS product_url text,
  ADD COLUMN IF NOT EXISTS tags text[];

-- Optional: set defaults for arrays to avoid null pitfalls
ALTER TABLE pet_products
  ALTER COLUMN tags SET DEFAULT '{}'::text[],
  ALTER COLUMN ingredients SET DEFAULT '{}'::text[],
  ALTER COLUMN contraindications SET DEFAULT '{}'::text[];

-- Optionally migrate legacy columns if they exist
-- UPDATE pet_products SET allowed_breeds = breeds_allowed WHERE allowed_breeds IS NULL AND breeds_allowed IS NOT NULL;
-- UPDATE pet_products SET ingredients = allergy_warning WHERE ingredients IS NULL AND allergy_warning IS NOT NULL;
-- UPDATE pet_products SET contraindications = medical_restriction WHERE contraindications IS NULL AND medical_restriction IS NOT NULL;

-- Recreate canonical view
DROP VIEW IF EXISTS breed_recommendations;

CREATE OR REPLACE VIEW breed_recommendations AS
SELECT
  p.id AS pet_id,
  p.name AS pet_name,
  pr.id AS product_id,
  pr.name AS product_name,
  pr.category,
  pr.price,
  pr.image_url,
  pr.product_url,
  pr.tags,
  CASE
    WHEN pr.allowed_breeds IS NOT NULL AND p.breed = ANY(pr.allowed_breeds) THEN 'Breed Match'
    WHEN LOWER(p.species) = LOWER(pr.species) THEN 'Species Match'
    ELSE 'General Recommendation'
  END AS match_reason
FROM pets p
JOIN pet_products pr ON LOWER(p.species) = LOWER(pr.species)
WHERE
  (pr.allowed_breeds IS NULL OR p.breed = ANY(pr.allowed_breeds))
  AND (pr.ingredients IS NULL OR NOT (pr.ingredients && COALESCE(p.allergies, '{}')))
  AND (pr.contraindications IS NULL OR NOT (pr.contraindications && COALESCE(p.medical_conditions, '{}')));
