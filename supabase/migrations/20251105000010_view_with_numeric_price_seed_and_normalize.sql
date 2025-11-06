R-- Recreate view with computed numeric_price, seed products per current schema, and add normalization procedure

-- 1) View: breed_recommendations with numeric_price
DROP VIEW IF EXISTS breed_recommendations;

CREATE OR REPLACE VIEW breed_recommendations AS
SELECT
  p.id AS pet_id,
  p.name AS pet_name,
  pr.id AS product_id,
  pr.name AS product_name,
  pr.category,
  pr.price, -- text
  pr.image_url,
  pr.product_url,
  pr.tags::text[] AS tags,
  (
    (CASE WHEN pr.breeds_allowed IS NOT NULL AND p.breed = ANY(pr.breeds_allowed::text[]) THEN 2 ELSE 0 END) +
    (CASE WHEN LOWER(p.animal) = LOWER(pr.species) THEN 1 ELSE 0 END)
  ) AS match_score,
  NULLIF(pr.price, '')::numeric NULLS LAST AS numeric_price,
  CASE
    WHEN pr.breeds_allowed IS NOT NULL AND p.breed = ANY(pr.breeds_allowed::text[]) THEN 'Breed Match'
    WHEN LOWER(p.animal) = LOWER(pr.species) THEN 'Species Match'
    ELSE 'General Recommendation'
  END AS match_reason
FROM pets p
JOIN pet_products pr ON LOWER(p.animal) = LOWER(pr.species)
WHERE
  (pr.breeds_allowed IS NULL OR p.breed = ANY(pr.breeds_allowed::text[]))
  AND (pr.allergy_warning IS NULL OR NOT (pr.allergy_warning::text[] && COALESCE(p.allergies::text[], '{}')))
  AND (pr.medical_restriction IS NULL OR NOT (pr.medical_restriction::text[] && COALESCE(p.medical_conditions::text[], '{}')));

-- 2) Seed products compatible with current schema (id bigint identity, price text, untyped arrays)
INSERT INTO pet_products (name, category, price, image_url, product_url, source, species, breeds_allowed, allergy_warning, medical_restriction, ingredients, tags)
VALUES
  ('Premium Dog Food', 'Food', '45.99', 'https://example.com/dog_food.jpg', 'https://shop.com/dog-food', 'seed',
    'dog', NULL, ARRAY['chicken','rice'], NULL, ARRAY['chicken','rice'], ARRAY['high-protein','grain-free']),
  ('Small Breed Dog Food', 'Food', '30.00', 'https://example.com/small_dog_food.jpg', 'https://shop.com/small-dog-food', 'seed',
    'dog', NULL, ARRAY['beef'], NULL, ARRAY['beef'], ARRAY['small-breed']),
  ('Hypoallergenic Dog Shampoo', 'Grooming', '15.00', 'https://example.com/dog_shampoo.jpg', 'https://shop.com/dog-shampoo', 'seed',
    'dog', NULL, NULL, ARRAY['skin-allergies'], NULL, ARRAY['sensitive-skin']),
  ('Indoor Cat Food', 'Food', '35.00', 'https://example.com/indoor_cat_food.jpg', 'https://shop.com/indoor-cat-food', 'seed',
    'cat', NULL, ARRAY['fish'], NULL, ARRAY['fish'], ARRAY['indoor','hairball-control']),
  ('Interactive Cat Laser Toy', 'Toys', '12.50', 'https://example.com/cat_laser.jpg', 'https://shop.com/cat-laser', 'seed',
    'cat', NULL, NULL, NULL, NULL, ARRAY['exercise'])
ON CONFLICT DO NOTHING;

-- 3) Normalization procedure for pets.animal
CREATE OR REPLACE FUNCTION normalize_pet_animals()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE pets SET animal = 'dog' WHERE animal ILIKE 'dog';
  UPDATE pets SET animal = 'cat' WHERE animal ILIKE 'cat';
  UPDATE pets SET animal = 'dog' WHERE animal ILIKE '%dogg%' OR animal ILIKE '%canine%';
  UPDATE pets SET animal = 'cat' WHERE animal ILIKE '%feline%';
  UPDATE pets SET animal = LOWER(TRIM(animal)) WHERE animal IS NOT NULL;
END;
$$;

-- Optionally call once on migration
SELECT normalize_pet_animals();
