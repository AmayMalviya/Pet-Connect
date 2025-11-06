-- Alter pets table
ALTER TABLE pets
ADD COLUMN IF NOT EXISTS allergies text[],
ADD COLUMN IF NOT EXISTS medical_conditions text[];

-- Alter pet_products table
ALTER TABLE pet_products
ADD COLUMN IF NOT EXISTS species text,
ADD COLUMN IF NOT EXISTS allowed_breeds text[],
ADD COLUMN IF NOT EXISTS ingredients text[],
ADD COLUMN IF NOT EXISTS contraindications text[];

-- Optional: Add some initial data to pet_products for testing
-- This is just an example, you might want to populate with more realistic data
INSERT INTO pet_products (id, name, category, price, image_url, tags, species, allowed_breeds, ingredients, contraindications)
VALUES
    (gen_random_uuid(), 'Premium Dog Food', 'Food', 45.99, 'https://example.com/dog_food.jpg', ARRAY['high-protein', 'grain-free'], 'dog', NULL, ARRAY['chicken', 'rice'], NULL),
    (gen_random_uuid(), 'Catnip Toy', 'Toys', 9.99, 'https://example.com/catnip_toy.jpg', ARRAY['interactive'], 'cat', NULL, ARRAY['catnip'], NULL),
    (gen_random_uuid(), 'Hypoallergenic Dog Shampoo', 'Grooming', 15.00, 'https://example.com/dog_shampoo.jpg', ARRAY['sensitive-skin'], 'dog', NULL, NULL, ARRAY['skin-allergies']),
    (gen_random_uuid(), 'Small Breed Dog Food', 'Food', 30.00, 'https://example.com/small_dog_food.jpg', ARRAY['small-breed'], 'dog', ARRAY['Chihuahua', 'Pomeranian'], ARRAY['beef'], NULL),
    (gen_random_uuid(), 'Large Breed Puppy Food', 'Food', 55.00, 'https://example.com/large_puppy_food.jpg', ARRAY['puppy', 'large-breed'], 'dog', ARRAY['German Shepherd', 'Golden Retriever'], ARRAY['lamb'], NULL),
    (gen_random_uuid(), 'Indoor Cat Food', 'Food', 35.00, 'https://example.com/indoor_cat_food.jpg', ARRAY['indoor', 'hairball-control'], 'cat', NULL, ARRAY['fish'], NULL),
    (gen_random_uuid(), 'Interactive Cat Laser Toy', 'Toys', 12.50, 'https://example.com/cat_laser.jpg', ARRAY['exercise'], 'cat', NULL, NULL, NULL),
    (gen_random_uuid(), 'Dental Chews for Dogs', 'Health', 20.00, 'https://example.com/dental_chews.jpg', ARRAY['dental-care'], 'dog', NULL, ARRAY['mint'], ARRAY['gum-disease']),
    (gen_random_uuid(), 'Flea & Tick Collar for Cats', 'Health', 25.00, 'https://example.com/flea_collar_cat.jpg', ARRAY['pest-control'], 'cat', NULL, NULL, ARRAY['skin-irritation']),
    (gen_random_uuid(), 'Bird Seed Mix', 'Food', 10.00, 'https://example.com/bird_seed.jpg', ARRAY['wild-birds'], 'bird', NULL, NULL, NULL)
ON CONFLICT (id) DO NOTHING;
