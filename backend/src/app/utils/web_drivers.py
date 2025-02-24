from contextlib import contextmanager
from typing import Generator
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import  (
    ElementClickInterceptedException,
    ElementNotInteractableException, 
    TimeoutException, 
    WebDriverException
    )
from selenium.webdriver.remote.webdriver import WebDriver
from fastapi import status
from app.exceptions import PlantServiceException, PlantServiceErrorCode
import logging

logger = logging.getLogger(__name__)

@contextmanager
def create_driver() -> Generator[tuple[WebDriver, WebDriverWait], None, None]:
    """
    Creates and manages a Chrome WebDriver session with appropriate error handling.

    Yields:
        Tuple[webdriver.Chrome, WebDriverWait]: Browser driver and wait object

    Raises:
        PlantServiceException: If browser initialisation fails
    """
    driver = webdriver.Chrome()
    try:
        driver.maximize_window()
        wait = WebDriverWait(driver, timeout=3)
        yield driver, wait
    except WebDriverException as e:    
        logger.info(f"WebDriverException: {str(e)}")
        raise PlantServiceException(
            error_code=PlantServiceErrorCode.BROWSER_ERROR,
            message="Failed to initialise browser",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            details={"error": str(e)}
        )
    finally:
        logger.info("About to quit driver")
        try:
            driver.quit()
        except Exception as e:
            logger.warning(f"Error quitting driver: {str(e)}")

class CookieConsentHandler:
    """Handles cookie consent popups across different website implementations."""
    
    BUTTON_CONFIGS = [
        {"by": By.CLASS_NAME, "value": "onetrust-close-btn-handler"},
        {"by": By.ID, "value": "onetrust-accept-btn-handler"},
        {"by": By.CSS_SELECTOR, "value": "button[aria-label='Close']"}
    ]

    @classmethod
    def handle(cls, driver: webdriver.Chrome, timeout: int=5) -> bool:
        """
        Attempts to handle cookie consent by trying multiple button configurations.

        Args:
            driver: Selenium WebDriver instance
            timeout: Maximum time to wait for each button, defaults to 3 seconds

        Returns:
            bool: True if successfully handled, False if no buttons were found
        """
        for config in cls.BUTTON_CONFIGS:
            try:
                button = WebDriverWait(driver, timeout).until(
                    EC.element_to_be_clickable((config["by"], config["value"]))
                )
                button.click()
                logger.info(f"Successfully clicked cookie consent button: {config['value']}")
                return True
            except (TimeoutException, ElementNotInteractableException, ElementClickInterceptedException):
                logger.debug(f"Could not find cookie button: {config['value']}")
                continue
        
        logger.warning("Could not handle cookie consent - no matching buttons found")
        return False
    
