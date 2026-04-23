"""
Amazon Product Scraper for Pet Connect
Fetches pet products from Amazon and stores them in Supabase
"""

import os
import requests
from bs4 import BeautifulSoup
import json
from supabase import create_client, Client
from datetime import datetime
import time
from typing import List, Dict, Optional
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# --- Supabase Credentials ---
SUPABASE_URL = "https://goegjrqmyshnzzonfjav.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvZWdqcnFteXNobnp6b25mamF2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzQ5MzI5MCwiZXhwIjoyMDczMDY5MjkwfQ.OYzKVNDtsauoX-GAk68bZUJdNSN0gb20VYpOKtj1atI"
# ---------------------------------

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Amazon search queries for different pet categories
AMAZON_SEARCH_QUERIES = {
    'dog_food': [
        'best dog food',
        'premium dog food',
        'puppy food',
        'senior dog food',
        'small breed dog food',
        'large breed dog food',
        'organic dog food',
        'grain free dog food',
    ],
    'cat_food': [
        'best cat food',
        'premium cat food',
        'kitten food',
        'senior cat food',
        'indoor cat food',
        'wet cat food',
        'dry cat food',
    ],
    'dog_toys': [
        'dog toys',
        'interactive dog toys',
        'durable dog toys',
        'puppy toys',
        'fetch toys for dogs',
        'chew toys for dogs',
    ],
    'cat_toys': [
        'cat toys',
        'interactive cat toys',
        'cat laser toy',
        'feather cat toys',
        'kitten toys',
    ],
    'dog_beds': [
        'dog bed',
        'orthopedic dog bed',
        'memory foam dog bed',
        'waterproof dog bed',
    ],
    'cat_beds': [
        'cat bed',
        'cat cave bed',
        'elevated cat bed',
        'heated cat bed',
    ],
    'grooming': [
        'dog grooming supplies',
        'dog shampoo',
        'dog brush',
        'cat grooming kit',
        'pet nail clippers',
    ],
    'treats': [
        'dog treats',
        'healthy dog treats',
        'cat treats',
        'pet training treats',
    ],
}

class AmazonProductScraper:
    def __init__(self):
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        }
        self.session = requests.Session()
        self.session.headers.update(self.headers)
        
    def search_amazon(self, query: str, max_results: int = 10) -> List[str]:
        """
        Search Amazon for products and return product URLs
        """
        try:
            # Using Amazon India for better local relevance
            search_url = f"https://www.amazon.in/s?k={query.replace(' ', '+')}"
            logger.info(f"Searching Amazon for: {query}")
            
            response = self.session.get(search_url, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            product_urls = []
            
            # Find product links
            products = soup.find_all('div', {'data-component-type': 's-search-result'})
            
            for product in products[:max_results]:
                link = product.find('a', {'class': 's-underline-text'})
                if link and link.get('href'):
                    product_url = 'https://www.amazon.in' + link['href']
                    product_urls.append(product_url)
            
            logger.info(f"Found {len(product_urls)} products for query: {query}")
            return product_urls
            
        except Exception as e:
            logger.error(f"Error searching Amazon for '{query}': {e}")
            return []
    
    def scrape_product_details(self, product_url: str) -> Optional[Dict]:
        """
        Scrape detailed information from an Amazon product page
        """
        try:
            logger.info(f"Scraping product: {product_url}")
            
            response = self.session.get(product_url, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Extract product name
            title_elem = soup.find('span', {'id': 'productTitle'})
            if not title_elem:
                logger.warning(f"Could not find title for {product_url}")
                return None
            
            name = title_elem.get_text(strip=True)
            
            # Extract price
            price = self._extract_price(soup)
            if not price:
                logger.warning(f"Could not find price for {name}")
                return None
            
            # Extract image URL
            image_url = self._extract_image_url(soup)
            
            # Extract rating
            rating = self._extract_rating(soup)
            
            # Extract product category from page
            category = self._extract_category(soup, name)
            
            # Determine pet type and species
            pet_type, species = self._determine_pet_type(name)
            
            # Generate tags
            tags = self._generate_tags(name, category)
            
            product_data = {
                'name': name,
                'product_url': product_url,
                'price': price,
                'image_url': image_url or '',
                'rating': rating,
                'source_website': 'Amazon',
                'category': category,
                'pet_type': pet_type,
                'species': species,
                'tags': tags,
                'source': 'amazon_scraper',
                'last_updated': datetime.now().isoformat(),
            }
            
            logger.info(f"Successfully scraped: {name} - ₹{price}")
            return product_data
            
        except Exception as e:
            logger.error(f"Error scraping product {product_url}: {e}")
            return None
    
    def _extract_price(self, soup: BeautifulSoup) -> Optional[str]:
        """Extract price from product page"""
        try:
            # Try different price selectors
            price_elem = soup.find('span', {'class': 'a-price-whole'})
            if price_elem:
                price_text = price_elem.get_text(strip=True)
                # Remove currency symbol and commas
                price = price_text.replace('₹', '').replace(',', '').strip()
                return price
            return None
        except Exception as e:
            logger.error(f"Error extracting price: {e}")
            return None
    
    def _extract_image_url(self, soup: BeautifulSoup) -> Optional[str]:
        """Extract main product image URL"""
        try:
            img_elem = soup.find('img', {'id': 'landingImage'})
            if img_elem and img_elem.get('src'):
                return img_elem['src']
            return None
        except Exception as e:
            logger.error(f"Error extracting image: {e}")
            return None
    
    def _extract_rating(self, soup: BeautifulSoup) -> Optional[float]:
        """Extract product rating"""
        try:
            rating_elem = soup.find('span', {'class': 'a-icon-star-small'})
            if rating_elem:
                rating_text = rating_elem.get_text(strip=True)
                rating = float(rating_text.split()[0])
                return rating
            return None
        except Exception as e:
            logger.error(f"Error extracting rating: {e}")
            return None
    
    def _extract_category(self, soup: BeautifulSoup, product_name: str) -> str:
        """Determine product category"""
        name_lower = product_name.lower()
        
        if any(word in name_lower for word in ['food', 'kibble', 'gravy', 'wet food']):
            return 'Food'
        elif any(word in name_lower for word in ['toy', 'ball', 'fetch', 'chew']):
            return 'Toys'
        elif any(word in name_lower for word in ['bed', 'mat', 'cushion']):
            return 'Beds'
        elif any(word in name_lower for word in ['shampoo', 'brush', 'grooming', 'nail']):
            return 'Grooming'
        elif any(word in name_lower for word in ['treat', 'snack', 'biscuit']):
            return 'Treats'
        elif any(word in name_lower for word in ['collar', 'leash', 'harness']):
            return 'Accessories'
        elif any(word in name_lower for word in ['supplement', 'vitamin', 'health']):
            return 'Health'
        else:
            return 'Accessories'
    
    def _determine_pet_type(self, product_name: str) -> tuple:
        """Determine pet type and species from product name"""
        name_lower = product_name.lower()
        
        if 'dog' in name_lower or 'puppy' in name_lower or 'canine' in name_lower:
            return 'dog', ['dog']
        elif 'cat' in name_lower or 'kitten' in name_lower or 'feline' in name_lower:
            return 'cat', ['cat']
        elif 'bird' in name_lower or 'parrot' in name_lower:
            return 'bird', ['bird']
        elif 'rabbit' in name_lower or 'bunny' in name_lower:
            return 'rabbit', ['rabbit']
        elif 'hamster' in name_lower or 'guinea pig' in name_lower:
            return 'hamster', ['hamster']
        else:
            return None, None
    
    def _generate_tags(self, product_name: str, category: str) -> List[str]:
        """Generate relevant tags for the product"""
        tags = set()
        name_lower = product_name.lower()
        
        # Pet type tags
        if 'dog' in name_lower:
            tags.add('dog')
        if 'cat' in name_lower:
            tags.add('cat')
        
        # Life stage tags
        if 'puppy' in name_lower:
            tags.add('puppy')
        if 'kitten' in name_lower:
            tags.add('kitten')
        if 'senior' in name_lower or 'adult' in name_lower:
            tags.add('senior')
        
        # Size tags
        if 'small' in name_lower:
            tags.add('small-breed')
        if 'large' in name_lower:
            tags.add('large-breed')
        if 'medium' in name_lower:
            tags.add('medium-breed')
        
        # Special diet tags
        if 'organic' in name_lower:
            tags.add('organic')
        if 'grain' in name_lower and 'free' in name_lower:
            tags.add('grain-free')
        if 'gluten' in name_lower and 'free' in name_lower:
            tags.add('gluten-free')
        if 'hypoallergenic' in name_lower:
            tags.add('hypoallergenic')
        
        # Category tag
        tags.add(category.lower())
        
        return list(tags)
    
    def scrape_and_store(self, category: str, queries: List[str], max_products_per_query: int = 5) -> int:
        """
        Scrape products for a category and store in Supabase
        """
        all_products = []
        
        for query in queries:
            logger.info(f"Processing category: {category}, query: {query}")
            
            # Search for products
            product_urls = self.search_amazon(query, max_results=max_products_per_query)
            
            # Scrape details for each product
            for url in product_urls:
                product_data = self.scrape_product_details(url)
                if product_data:
                    all_products.append(product_data)
                
                # Be respectful to Amazon servers
                time.sleep(2)
            
            # Delay between queries
            time.sleep(3)
        
        # Store in Supabase
        if all_products:
            try:
                logger.info(f"Storing {len(all_products)} products in Supabase...")
                
                # Use upsert to avoid duplicates based on product_url
                response = supabase.table('pet_products').upsert(
                    all_products,
                    on_conflict='product_url'
                ).execute()
                
                logger.info(f"Successfully stored {len(all_products)} products")
                return len(all_products)
                
            except Exception as e:
                logger.error(f"Error storing products in Supabase: {e}")
                return 0
        
        return 0


def scrape_all_categories():
    """
    Scrape all product categories and store in database
    """
    scraper = AmazonProductScraper()
    total_products = 0
    
    for category, queries in AMAZON_SEARCH_QUERIES.items():
        logger.info(f"\n{'='*60}")
        logger.info(f"Scraping category: {category}")
        logger.info(f"{'='*60}")
        
        count = scraper.scrape_and_store(category, queries, max_products_per_query=5)
        total_products += count
        
        # Delay between categories
        time.sleep(5)
    
    logger.info(f"\n{'='*60}")
    logger.info(f"SCRAPING COMPLETE - Total products scraped: {total_products}")
    logger.info(f"{'='*60}")
    
    return total_products


if __name__ == '__main__':
    # Run the scraper
    scrape_all_categories()
