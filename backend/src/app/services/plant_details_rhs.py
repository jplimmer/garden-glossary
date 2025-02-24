"""Service to extract key cultivation details about a plant from the RHS website."""

import asyncio
from fastapi import status
from app.utils import create_driver, CookieConsentHandler
from app.models import Size, Soil, Position, PlantDetails
from app.exceptions import PlantServiceErrorCode, PlantServiceException
from typing import Optional, List
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import  (
    StaleElementReferenceException, 
    TimeoutException, 
    WebDriverException
    )
from bs4 import BeautifulSoup
import logging

logger = logging.getLogger(__name__)

class PlantScraper:
    """
    A web scraper for extracting plant details from the RHS website.

    Uses Selenium WebDriver for dynamic content and BeautifulSoup for parsing.
    
    Args:
        base_url (str): The base URL for RHS plant search queries.
    
    Raises:
        PlantServiceException: If base_url is empty or invalid.
    """
    def __init__(self, base_url: str):
        if not base_url:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.SERVICE_INITIALIZATION,
                message="Base URL cannot be empty",
                status_code=status.HTTP_400_BAD_REQUEST
            )
        self.base_url = base_url

    def _find_plant_details(self, soup: BeautifulSoup, selector: str) -> Optional[BeautifulSoup]:
        """
        Locate parent div for specific section within the parsed HTML.
        
        Args:
            soup (BeautifulSoup): Parsed HTML from the RHS website.
            selector (str): Name of the section title (H6) to search for.

        Returns:
            Optional[BeautifulSoup]: Soup for the section if title found, None otherwise.
        """
        try:
            panel = soup.find('h6', string=selector)
            return panel.find_parent('div', class_='plant-attributes__panel') if panel else None
        except AttributeError:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.PARSING_ERROR,
                message=f"Failed to parse {selector} section",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def _extract_size(self, soup: BeautifulSoup) -> Optional[Size]:
        """
        Extract plant size information from the parsed HTML.
        
        Args:
            soup (BeautifulSoup): Parsed HTML containing size information.

        Returns:
            Optional[Size]: Size details if found, None otherwise.
        """
        size_panel = self._find_plant_details(soup, 'Size')
        if not size_panel:
            return None
        
        return Size(
            height = self._extract_field(size_panel, 'Ultimate height'),
            spread = self._extract_field(size_panel, 'Ultimate spread'),
            time_to_height = self._extract_field(size_panel, 'Time to ultimate height'),
        )
    
    def _extract_hardiness(self, soup: BeautifulSoup) -> Optional[str]:
        """
        Extract plant hardiness from the parsed HTML.

        Args:
            soup (BeautifulSoup): Parsed HTML containing hardiness information.

        Returns:
            Optional[str]: Hardiness rating and desriptor if found, None otherwise.
        """
        pos_panel = self._find_plant_details(soup, 'Position')
        if not pos_panel:
            return None
        
        for h6 in pos_panel.find_all('h6', class_='u-m-b-0'):
            if 'Hardiness' in h6.get_text():
                rating = h6.parent.find('span', recursive=False)
                if rating and rating.text:
                    hardiness_strong = h6.find('strong', string=lambda text: rating.text in text)
                    if hardiness_strong:
                        return hardiness_strong.parent.text
                    
        return None
    
    def _extract_soil(self, soup: BeautifulSoup) -> Optional[Soil]:
        """
        Extract soil requirements from the parsed HTML.

        Args:
            soup (BeautifulSoup): Parsed HTML containing soil information.

        Returns:
            Optional[Soil]: Soil requirements if found, None otherwise.
        """
        gc_panel = self._find_plant_details(soup, 'Growing conditions')
        if not gc_panel:
            return None
        
        # Extract soil types
        soil_types = []
        for flag in gc_panel.find_all('div', class_='flag__body'):
            if flag.text.strip():
                soil_types.append(flag.text.strip())

        # Extract moisture levels
        moisture = self._extract_list_field(gc_panel, 'Moisture')

        # Extract pH levels
        ph = self._extract_list_field(gc_panel, 'pH')

        if soil_types or moisture or ph:
            return Soil(
                types=soil_types,
                moisture=moisture or [],
                ph_levels=ph or []
            )
        return None
    
    def _extract_list_field(self, panel: BeautifulSoup, field_name: str) -> List[str]:
        """
        Extract a field with multiple strings from a panel.

        Args:
            panel (BeautifulSoup): Panel containing the field.
            field_name (str): Name of the field to extract.

        Returns:
            List[str]: Field values if found, None otherwise.
        """
        field_h6 = panel.find('h6', string=field_name)
        if not field_h6:
            return []
        
        parent = field_h6.find_parent('div', class_='l-module')
        if not parent:
            return []
        
        return [span.text.strip().replace(',', '') 
                for span in parent.find('span')
                if span.text.strip()]
    
    def _extract_position(self, soup: BeautifulSoup) -> Optional[Position]:
        """
        Extract position and sunlight requirements from the parsed HTML.

        Args:
            soup (BeautifulSoup): Parsed HTML containing position information.

        Returns:
            Optional[Position]: Position requirements if found, None otherwise.
        """
        pos_panel = self._find_plant_details(soup, 'Position')
        if not pos_panel:
            return None
        
        content = pos_panel.find('div', class_='plant-attributes__content')
        if not content:
            return None
        
        position = Position()

        # Extract sun info
        sun_div = content.find('div', class_='flag--tiny')
        if sun_div and sun_div.text:
            position.sun = sun_div.text.strip()

        # Extract aspect info
        aspect_p = content.find('p')
        if aspect_p:
            aspect_spans = aspect_p.find_all('span')
            if aspect_spans:
                position.aspect = ' '.join(span.text.strip() for span in aspect_spans if span.text)

        # Extract exposure info
        exposure = self._extract_list_field(content, 'Exposure')
        if exposure:
            position.exposure = ' '.join(exposure)

        return position if (position.sun or position.aspect or position.exposure) else None
    
    def _extract_cultivation_tips(self, soup: BeautifulSoup) -> Optional[str]:
        """
        Extract cultivation tips from the parsed HTML.

        Args:
            soup (BeautifulSoup): Parsed HTML containing cultivation information.

        Returns:
            Optional[str]: Cultivation tips if found, None otherwise.
        """
        cult_h5 = soup.find('h5', string='Cultivation')
        if not cult_h5:
            return None
        
        cult_span = cult_h5.find_parent('span')
        if not cult_span:
            return None
        
        p_tag = cult_span.find('p')
        if not p_tag:
            return None
        
        text_parts = []
        for element in p_tag.children:
            if element.name == 'a' and element.get('href'):
                text_parts.append(f'<a href="{element["href"]}">{element.text}</a>')
            elif isinstance(element, str):
                text_parts.append(element)

        return ''.join(text_parts) if text_parts else None
    
    def _extract_pruning(self, soup: BeautifulSoup) -> Optional[str]:
        """
        Extract pruning tips from the parsed HTML.

        Args:
            soup (BeautifulSoup): Parsed HTML containing pruning information.

        Returns:
            Optional[str]: Pruning tips if found, None otherwise.
        """
        pruning_h5 = soup.find('h5', string='Pruning')
        if not pruning_h5:
            return None
        
        pruning_span = pruning_h5.find_parent('span')
        if not pruning_span:
            return None
        
        p_tag = pruning_span.find('p')
        if not p_tag:
            return None
        
        text_parts = []
        for element in p_tag.children:
            if element.name == 'a' and element.get('href'):
                text_parts.append(f'<a href="{element["href"]}">{element.text}</a>')
            elif isinstance(element, str):
                text_parts.append(element)

        return ''.join(text_parts) if text_parts else None
    
    def _extract_field(self, panel: BeautifulSoup, field_name: str) -> Optional[str]:
        """
        Extract a single field value from a panel.

        Args:
            panel (BeautifulSoup): Panel containing the field.
            field_name (str): Name of the field to extract.

        Returns:
            Optional[str]: Field value if found, None otherwise.
        """
        field_div = panel.find('h6', string=field_name)
        if field_div:
            parent_div = field_div.find_parent('div', class_='flag__body')
            return parent_div.contents[-1].strip() if parent_div else None
        return None
    
    def get_plant_details(self, species: str) -> Optional[PlantDetails]:
        """
        Retrieve detailed information about a plant species from the RHS website.

        Args:
            species (Str): The plant species name to search for.

        Returns:
            Optional[PlantDetails]: Plant details if found, None otherwise
        
        Raises:
            PlantServiceException: If species is empty, network error occurs, or parsing fails.
        """
        try:
            if not species:
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.VALIDATION_ERROR,
                    message="Species name cannot be empty",
                    status_code=status.HTTP_400_BAD_REQUEST
                )

            species_query = species.replace(" ", "%20").lower()
            url = f"{self.base_url}{species_query}"

            with create_driver() as (driver, wait):
                try:
                    driver.get(url)
                except WebDriverException as e:
                    raise PlantServiceException(
                        error_code=PlantServiceErrorCode.NETWORK_ERROR,
                        message=f"Failed to access RHS website at {url}",
                        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                        details={"error": str(e)}
                    )
                
                # Handle cookie consent
                logger.info("About to handle cookie consent")
                if not CookieConsentHandler.handle(driver):
                    raise PlantServiceException(
                        error_code=PlantServiceErrorCode.COOKIE_CONSENT_FAILED,
                        message="Failed to handle cookie consent",
                        status_code=status.HTTP_503_SERVICE_UNAVAILABLE
                    )
                
                # Scroll to bottom and find matching result
                try:
                    driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                    search_results = wait.until(
                        EC.presence_of_all_elements_located((
                            By.CSS_SELECTOR, 'app-plant-search-list a.u-faux-block-link__overlay'
                        ))
                    )
                except TimeoutException:
                    raise PlantServiceException(
                        error_code=PlantServiceErrorCode.NO_RESULTS_FOUND,
                        message=f"No search results found for species '{species}'",
                        status_code=status.HTTP_404_NOT_FOUND
                    )

                match_found = False

                # Check for strict match and click
                logging.info("Checking search results for matches...")
                for result in search_results:
                    if species.lower() == result.get_attribute('innerText').strip().lower():
                        match_found = True
                        logger.info(f"Match found for species: '{species}'")
                        result.click()
                        break
                
                # If no strict match, check for "species + (" and click
                if not match_found:
                    for result in search_results:
                        # logger.info(f"{result.get_attribute('innerText')}")
                        if f"{species.lower()} (" in result.get_attribute('innerText').lower():
                            match_found = True
                            logger.info(f"'Bracket match' found for species '{species}'")
                            result.click()
                            break
                
                # If no match, raise Exception
                if not match_found:
                    logger.warning(f"No match found for species: {species}")
                    raise PlantServiceException(
                        error_code=PlantServiceErrorCode.NO_RESULTS_FOUND,
                        message=f"No matching search results found for '{species}'",
                        status_code=status.HTTP_404_NOT_FOUND
                    )
                
                # Check if page contains full details or only summary
                full_details_selector = 'lib-plant-details-full'
                summary_selector = 'lib-plant-details-summary'
                try:
                    logger.info("Entered elements try block")
                    driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                    
                    element = wait.until(
                        EC.presence_of_element_located((
                            By.CSS_SELECTOR,
                            f"{full_details_selector}, {summary_selector}"
                        ))
                    )
                    logger.info(f"Element found: {element.tag_name}")
                    
                    # If only summary found, raise Exception
                    if element.tag_name == summary_selector:
                        raise PlantServiceException(
                            error_code=PlantServiceErrorCode.NO_RESULTS_FOUND,
                            message=f"RHS has no detailed information for '{species}', only a brief summary",
                            status_code=status.HTTP_404_NOT_FOUND
                        )
                    
                    # Otherwise wait for full details to render
                    wait.until(
                        EC.visibility_of_element_located((By.CSS_SELECTOR, f"{full_details_selector}"))
                    )
                    logger.info("Full details visibile - implicitly waiting 1 second")
                    driver.implicitly_wait(1)

                except TimeoutException:
                    raise PlantServiceException(
                        error_code=PlantServiceErrorCode.PARSING_ERROR,
                        message="Timed out waiting for plant details element to load",
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )

                # Extract details
                logging.info("Getting soup...")
                soup = BeautifulSoup(driver.page_source, "lxml")
                return self._extract_all_details(soup)
            
        except StaleElementReferenceException as e:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.PARSING_ERROR,
                message="Page elements became stale during processing",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        except Exception as e:
            if isinstance(e, PlantServiceException):
                raise
            logger.debug(f"Exception: str{e}")
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.PARSING_ERROR,
                message="Failed to process plant details",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                details={"error": str(e)}
            )
            
    def _extract_all_details(self, soup: BeautifulSoup) -> PlantDetails:
        """
        Extract all plant details from the parsed HTML.

        Args:
            soup (BeautifulSoup): Parsed HTML of the RHS page for the plant species.

        Returns:
            PlantDetails: Structured plant information
        """
        return PlantDetails(
            size=self._extract_size(soup),
            hardiness=self._extract_hardiness(soup),
            soil=self._extract_soil(soup),
            position=self._extract_position(soup),
            cultivation_tips=self._extract_cultivation_tips(soup),
            pruning=self._extract_pruning(soup)
        )

# Service-layer class
class PlantDetailsRhsService:
    """
    Service layer for retrieving plant details from the RHS website.
    Provides asynchronous access to plant information.
    """
    @staticmethod
    async def retrieve_plant_details(plant: str) -> PlantDetails:
        """
        Asynchronously retrieve plant details from RHS website.

        Args:
            plant (str): Name of the plant species to search for.
        
        Returns:
            dict: Structured plant information including size, hardiness, 
                  soil requirements, position, cultivation tips and pruning.

        Raises:
            PlantServiceException: If retrieval fails for any reason.
        """
        try:
            scraper = PlantScraper(base_url='https://www.rhs.org.uk/plants/search-results?query=')

            details = await asyncio.to_thread(scraper.get_plant_details, plant)
            
            if details is None:
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.NO_RESULTS_FOUND,
                    message=f"No details found on RHS website for '{plant}'",
                    status_code=status.HTTP_404_NOT_FOUND
                )
            
            try:
                logging.info(f"Details: {details}")
                return details
            except asyncio.TimeoutError:
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.TIMEOUT_ERROR,
                    message="Operation timed out",
                    status_code=status.HTTP_504_GATEWAY_TIMEOUT
                )
            except Exception as e:
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.PARSING_ERROR,
                    message="Failed to process plant details",
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    details={"error": str(e)}
                )

        except Exception as e:
            if isinstance(e, PlantServiceException):
                raise
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.SERVICE_ERROR,
                message="Unexpected error",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                details={"error": str(e)}
            )
    
