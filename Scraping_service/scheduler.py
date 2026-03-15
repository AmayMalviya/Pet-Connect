"""
Scheduled Product Scraper for Pet Connect
Runs the Amazon scraper at regular intervals to keep product database fresh
"""

import schedule
import time
import logging
from datetime import datetime
from amazon_scraper import scrape_all_categories, AmazonProductScraper, AMAZON_SEARCH_QUERIES

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('scraper.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


def scheduled_scrape_job():
    """
    Job that runs at scheduled intervals to scrape products
    """
    logger.info(f"\n{'='*80}")
    logger.info(f"SCHEDULED SCRAPE JOB STARTED - {datetime.now()}")
    logger.info(f"{'='*80}\n")
    
    try:
        total = scrape_all_categories()
        logger.info(f"\nScheduled scrape completed successfully. Total products: {total}")
    except Exception as e:
        logger.error(f"Error in scheduled scrape job: {e}", exc_info=True)
    
    logger.info(f"\nNext scheduled scrape: {schedule.next_run()}\n")


def scheduled_category_scrape(category: str, queries: list):
    """
    Scrape a specific category
    """
    logger.info(f"\nScheduled scrape for category: {category}")
    
    try:
        scraper = AmazonProductScraper()
        count = scraper.scrape_and_store(category, queries, max_products_per_query=3)
        logger.info(f"Scraped {count} products for category: {category}")
    except Exception as e:
        logger.error(f"Error scraping category {category}: {e}", exc_info=True)


def setup_schedules():
    """
    Setup all scheduled tasks
    """
    logger.info("Setting up scheduled tasks...")
    
    # Full scrape every 24 hours at 2 AM
    schedule.every().day.at("02:00").do(scheduled_scrape_job)
    logger.info("✓ Full scrape scheduled daily at 02:00")
    
    # Scrape specific categories at different times to distribute load
    # Dog food - every 12 hours
    schedule.every(12).hours.do(
        scheduled_category_scrape,
        'dog_food',
        AMAZON_SEARCH_QUERIES['dog_food']
    )
    logger.info("✓ Dog food scrape scheduled every 12 hours")
    
    # Cat food - every 12 hours (offset by 6 hours)
    schedule.every(12).hours.do(
        scheduled_category_scrape,
        'cat_food',
        AMAZON_SEARCH_QUERIES['cat_food']
    )
    logger.info("✓ Cat food scrape scheduled every 12 hours")
    
    # Toys - every 24 hours
    schedule.every().day.at("06:00").do(
        scheduled_category_scrape,
        'dog_toys',
        AMAZON_SEARCH_QUERIES['dog_toys']
    )
    logger.info("✓ Dog toys scrape scheduled daily at 06:00")
    
    # Treats - every 48 hours
    schedule.every(48).hours.do(
        scheduled_category_scrape,
        'treats',
        AMAZON_SEARCH_QUERIES['treats']
    )
    logger.info("✓ Treats scrape scheduled every 48 hours")
    
    logger.info("All scheduled tasks configured successfully!\n")


def run_scheduler():
    """
    Run the scheduler in an infinite loop
    """
    setup_schedules()
    
    logger.info("Scheduler started. Waiting for scheduled tasks...")
    logger.info(f"Current time: {datetime.now()}\n")
    
    try:
        while True:
            schedule.run_pending()
            time.sleep(60)  # Check every minute
    except KeyboardInterrupt:
        logger.info("\nScheduler stopped by user")
    except Exception as e:
        logger.error(f"Scheduler error: {e}", exc_info=True)


def run_once():
    """
    Run the scraper once (useful for testing or manual execution)
    """
    logger.info("Running scraper once...")
    scheduled_scrape_job()


if __name__ == '__main__':
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == '--once':
        # Run once and exit
        run_once()
    else:
        # Run scheduler continuously
        run_scheduler()
