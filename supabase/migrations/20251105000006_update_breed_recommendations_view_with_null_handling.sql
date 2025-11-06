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
    WHEN p.breed = ANY(pr.breeds_allowed) THEN 'Breed Match'
    WHEN p.animal = pr.species THEN 'Species Match'
    ELSE 'General Recommendation'
  END AS match_reason
FROM pets p
JOIN pet_products pr ON LOWER(p.animal) = LOWER(pr.species)
WHERE
  (pr.breeds_allowed IS NULL OR p.breed = ANY(pr.breeds_allowed))
  AND (pr.allergy_warning IS NULL OR NOT (pr.allergy_warning && COALESCE(p.allergies, '{}')))
  AND (pr.medical_restriction IS NULL OR NOT (pr.medical_restriction && COALESCE(p.medical_conditions, '{}')));