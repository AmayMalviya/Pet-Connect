import os
import requests
from bs4 import BeautifulSoup
import json
from supabase import create_client, Client

# Supabase Credentials
SUPABASE_URL = "https://goegjrqmyshnzzonfjav.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvZWdqcnFteXNobnp6b25mamF2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzQ5MzI5MCwiZXhwIjoyMDczMDY5MjkwfQ.OYzKVNDtsauoX-GAk68bZUJdNSN0gb20VYpOKtj1atI"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def generate_tags(product_name):
    """
    Analyzes a product name and generates a list of relevant tags.
    """
    tags = set()
    name_lower = product_name.lower()
    
    # Pet type
    if 'dog' in name_lower or 'puppy' in name_lower:
        tags.add('dog')
    if 'cat' in name_lower or 'kitten' in name_lower:
        tags.add('cat')
        
    # Life stage
    if 'puppy' in name_lower:
        tags.add('puppy')
    if 'kitten' in name_lower:
        tags.add('kitten')
    if 'adult' in name_lower:
        tags.add('adult')
    if 'senior' in name_lower:
        tags.add('senior')
        
    # Product category
    if 'food' in name_lower or 'kibble' in name_lower or 'gravy' in name_lower:
        tags.add('food')
    if 'toy' in name_lower:
        tags.add('toy')
    if 'treat' in name_lower:
        tags.add('treat')
        
    # Breed size
    if 'small breed' in name_lower:
        tags.add('small_breed')
    if 'medium breed' in name_lower:
        tags.add('medium_breed')
    if 'large breed' in name_lower:
        tags.add('large_breed')
        
    return list(tags)

def get_product_urls(collection_url):
    # This function is already working well, no changes needed.
    print(f"Fetching product links from {collection_url}...")
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
    try:
        response = requests.get(collection_url, headers=headers)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        return []
    soup = BeautifulSoup(response.content, 'html.parser')
    product_urls = set()
    all_links = soup.find_all('a')
    for link in all_links:
        if link.has_attr('href') and '/products/' in link['href']:
            href = link['href']
            if href.startswith('http'):
                full_url = href
            else:
                full_url = "https://supertails.com" + href
            product_urls.add(full_url)
    print(f"Found {len(product_urls)} unique product URLs.")
    return list(product_urls)

def scrape_product_details(product_url):
    # This function is mostly the same, just with the tag generation added.
    print(f"  - Scraping {product_url}")
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
    try:
        response = requests.get(product_url, headers=headers)
        response.raise_for_status()
    except requests.exceptions.RequestException:
        return None
    soup = BeautifulSoup(response.content, 'html.parser')
    json_script_tag = soup.find('script', type='application/ld+json')
    if not json_script_tag:
        return None
    try:
        product_data = json.loads(json_script_tag.string)
        name = product_data.get('name')
        image_object = product_data.get('image', {})
        image_url = image_object.get('url') if isinstance(image_object, dict) else None
        offers = product_data.get('offers')
        price = None
        if isinstance(offers, list) and offers:
            price = offers[0].get('price')
        elif isinstance(offers, dict):
            price = offers.get('price')

        if name and product_url and price:
            # *** NEW: Generate tags and add them to the product data ***
            tags = generate_tags(name)
            return {
                "name": name,
                "url": product_url,
                "price": price,
                "image_url": image_url,
                "vendor": "Supertails",
                "tags": tags  # Add the new tags here
            }
    except (json.JSONDecodeError, AttributeError):
        return None
    return None

if __name__ == '__main__':
    collection_url = "https://supertails.com/collections/dog-food"
    product_urls = get_product_urls(collection_url)
    all_products = []
    if product_urls:
        print("\nScraping details for each product...")
        for url in product_urls:
            details = scrape_product_details(url)
            if details:
                all_products.append(details)
    
    print("\n--- SCRAPING COMPLETE ---")
    print(f"Successfully scraped {len(all_products)} products.")
    
    if all_products:
        print("\n--- Uploading data to Supabase ---")
        try:
            data, count = supabase.table('pet_products').upsert(all_products, on_conflict='url').execute()
            print(f"Successfully upserted {len(data[1])} products into Supabase.")
        except Exception as e:
            print(f"Error uploading to Supabase: {e}")