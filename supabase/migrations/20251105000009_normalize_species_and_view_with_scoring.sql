-- Normalize species values in pets and enhance the recommendations view with scoring

-- Normalize existing species values to canonical lowercase forms where obvious
-- Map common variants to 'dog' or 'cat'; extend as needed
UPDATE pets SET species = 'dog' WHERE species ILIKE 'dog';
UPDATE pets SET species = 'cat' WHERE species ILIKE 'cat';
-- Handle some common noisy variants
UPDATE pets SET species = 'dog' WHERE species ILIKE '%dogg%'
  OR species ILIKE '%canine%';
UPDATE pets SET species = 'cat' WHERE species ILIKE '%feline%';

-- Ensure species is trimmed and lowercased for other rows
UPDATE pets SET species = LOWER(TRIM(species)) WHERE species IS NOT NULL;

-- Recreate view with match_score for ranking
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
  (
    (CASE WHEN pr.allowed_breeds IS NOT NULL AND p.breed = ANY(pr.allowed_breeds) THEN 2 ELSE 0 END) +
    (CASE WHEN LOWER(p.species) = LOWER(pr.species) THEN 1 ELSE 0 END)
  ) AS match_score,
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
