-- Seed initial pet_products for testing recommendations

INSERT INTO pet_products (id, name, category, price, image_url, product_url, tags, species, allowed_breeds, ingredients, contraindications)
VALUES
  (gen_random_uuid(), 'Premium Dog Food', 'Food', 45.99, 'https://example.com/dog_food.jpg', 'https://shop.com/dog-food', ARRAY['high-protein','grain-free'], 'dog', NULL, ARRAY['chicken','rice'], NULL),
  -- Relax allowed_breeds to broaden matching for demo
  (gen_random_uuid(), 'Small Breed Dog Food', 'Food', 30.00, 'https://example.com/small_dog_food.jpg', 'https://shop.com/small-dog-food', ARRAY['small-breed'], 'dog', NULL, ARRAY['beef'], NULL),
  (gen_random_uuid(), 'Indoor Cat Food', 'Food', 35.00, 'https://example.com/indoor_cat_food.jpg', 'https://shop.com/indoor-cat-food', ARRAY['indoor','hairball-control'], 'cat', NULL, ARRAY['fish'], NULL),
  (gen_random_uuid(), 'Hypoallergenic Dog Shampoo', 'Grooming', 15.00, 'https://example.com/dog_shampoo.jpg', 'https://shop.com/dog-shampoo', ARRAY['sensitive-skin'], 'dog', NULL, NULL, ARRAY['skin-allergies']),
  (gen_random_uuid(), 'Interactive Cat Laser Toy', 'Toys', 12.50, 'https://example.com/cat_laser.jpg', 'https://shop.com/cat-laser', ARRAY['exercise'], 'cat', NULL, NULL, NULL)
ON CONFLICT (id) DO NOTHING;
