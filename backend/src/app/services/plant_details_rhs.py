"""Service to extract key cultivation details about a plant from the RHS website."""
import asyncio
import json
import logging
from typing import List, Optional

import requests
from bs4 import BeautifulSoup
from fastapi import status

from app.config import settings
from app.exceptions import PlantServiceErrorCode, PlantServiceException
from app.models import PlantDetails, Position, Size, Soil

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
        else:
            logger.warning(f"H6 tag '{field_name}' not found")
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
                for span in parent.find_all('span')
                if span.text.strip()]

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
            logger.warning("Size panel not found in soup")
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
            logger.warning("Position panel not found in soup")
            return None

        logger.debug("Searching for hardiness information in Position panel")
        for h6 in pos_panel.find_all('h6', class_='u-m-b-0'):
            if 'Hardiness' in h6.get_text():
                logger.debug("Found hardiness header in panel")
                rating = h6.parent.find('span', recursive=False)
                if rating and rating.text:
                    hardiness_strong = h6.find('strong', string=lambda text: rating.text.capitalize() in text)
                    if hardiness_strong:
                        hardiness_text = hardiness_strong.parent.text
                        logger.debug(f"Successfully extracted hardiness: {hardiness_text}")
                        return hardiness_text
                    else:
                        logger.debug("Strong tag with matching rating not found")
                else:
                    logger.debug("No rating span found or empty text")

        logger.warning("Hardiness information not found in Position panel")
        return 'Hardiness rating not found'

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
            logger.warning("Growing conditions panel not found in soup")
            return None

        logger.debug("Searching for soil information in Growing conditions panel")
        # Extract soil types
        soil_types = []
        for flag in gc_panel.find_all('div', class_='flag__body'):
            if flag.text.strip():
                soil_types.append(flag.text.strip())
            else:
                logger.debug("No soil flags with text found")

        # Extract moisture levels
        moisture = self._extract_list_field(gc_panel, 'Moisture')

        # Extract pH levels
        ph = self._extract_list_field(gc_panel, 'pH')

        if soil_types or moisture or ph:
            soil_info = Soil(
                types=soil_types,
                moisture=moisture or [],
                ph_levels=ph or []
            )
            logger.debug(f"Successfully extracted soil info: {soil_info}")
            return soil_info
        logger.warning("Soil information not found in Growing conditions panel")
        return None

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
            logger.warning("Position panel not found in soup")
            return None

        content = pos_panel.find('div', class_='plant-attributes__content')
        if not content:
            logger.warning("Plant attributes content not found in Position panel")
            return None

        logger.debug("Searching for position information in Position panel")
        position = Position()

        # Extract sun info
        sun_types = []
        for flag in content.find_all('div', class_='flag--tiny'):
            if flag.text.strip():
                sun_types.append(flag.text.strip())
            else:
                logger.debug("No sun flags with text found")
        position.sun = sun_types

        # Extract aspect info
        aspect_p = content.find('p')
        if aspect_p:
            aspect_spans = aspect_p.find_all('span')
            if aspect_spans:
                position.aspect = ' '.join(span.text.strip() for span in aspect_spans if span.text)
            else:
                logger.debug("No aspect spans found")
        else:
            logger.debug("No p tag found within Plant attributes content")

        # Extract exposure info
        exposure = self._extract_list_field(content, 'Exposure')
        if exposure:
            position.exposure = ' '.join(exposure)

        if (position.sun or position.aspect or position.exposure):
            logger.debug(f"Successfully extracted position info: {position}")
            return position
        logger.warning("Position info not found in Position panel")
        return None

    def _extract_href_text_field(self, soup: BeautifulSoup, field_name: str) -> Optional[str]:
        """
        Extract text section with href links from the parsed HTML.

        Args:
            soup (BeautifulSoup): Parsed HTML containing required information.
            field_name(str): Name of the field to extract.

        Returns:
            Optional[str]: Text with href links if found, None otherwise.
        """
        field_div = soup.find('h5', string=field_name)
        if not field_div:
            logger.warning(f"H5 tag {field_name} not found in soup")
            return None

        parent_span = field_div.find_parent('span')
        if not parent_span:
            logger.warning(f"Parent span for {field_name} not found in soup")
            return None

        p_tag = parent_span.find('p')
        if not p_tag:
            logger.warning(f"P tag for {field_name} not found in soup")
            return None

        text_parts = []
        for element in p_tag.children:
            if element.name == 'a' and element.get('href'):
                text_parts.append(f'<a href="{element["href"]}">{element.text}</a>')
            elif isinstance(element, str):
                text_parts.append(element)

        if text_parts:
            full_text = ''.join(text_parts).strip()
            if full_text and not full_text.endswith('.'):
                full_text += '.'

        if full_text:
            logger.debug(f"Successfully extracted html text for {field_name}: {full_text}")
            return full_text
        logger.warning(f"Html text for {field_name} not found in soup")
        return None

    def search_rhs_plants(self, species: str) -> Optional[PlantDetails]:
        """
        Perform a search for a plant species on the RHS website.

        Args:
            species (str): Plant species name to search for.

        Returns:
            List of search results (max 20).

        Raises:
            PlantServiceException for various error conditions.
        """
        if not species:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.VALIDATION_ERROR,
                message="Species name cannot be empty",
                status_code=status.HTTP_400_BAD_REQUEST
            )

        headers = {
            "accept": "application/json, text/plain, */*",
            "content-type": "application/json",
            "referrer": "https://www.rhs.org.uk/plants/search-form",
            "referrerPolicy": "no-referrer-when-downgrade"
        }

        search_payload = {
            "pageSize": 20,
            "startFrom": 0,
            "keywords": species
        }

        try:
            logger.info(f"Sending search request for {species}...")
            response = requests.post(
                settings.RHS_SEARCH_API_URL,
                headers=headers,
                data=json.dumps(search_payload),
                timeout=10
            )
            response.raise_for_status()
        except requests.Timeout as e:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.TIMEOUT_ERROR,
                message=f"Search request timed out for {species}",
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                details={"error": str(e)}
            )
        except requests.RequestException as e:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.NETWORK_ERROR,
                message=f"Failed to search RHS for {species}",
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                details={"error": str(e)}
            )

        search_results = response.json().get('hits', [])
        if not search_results:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.PARSING_ERROR,
                message="Empty response from RHS search API",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        return search_results

    def find_match(self, species: str, search_results: List[dict]) -> str:
        """
        Find the best matching plant URL from search results.

        Args:
            species (str): Original search species.
            search_results (List[dict]): Search results from RHS.

        Returns:
            str: Matched plant details URL

        Raises:
            PlantServiceException if no match found.
        """
        species_lower = species.lower()
        logger.info("Checking search results for matches...")

        match_found = False

        # Check for exact match
        for result in search_results:
            name = BeautifulSoup(result.get('botanicalName'), "html.parser").get_text().lower()
            if species_lower == name:
                match_found = True
                logger.info(f"Exact match found for '{name}'")
                return self._get_match_link(result, name)

        # If no exact match, check for "species + ("
        if not match_found:
            for result in search_results:
                name = BeautifulSoup(result.get('botanicalName'), "html.parser").get_text().lower()
                if f"{species_lower} (" in name:
                    match_found = True
                    logger.info(f"'Bracket match' found for '{name}'")
                    return self._get_match_link(result, name)

        # If no match, raise Exception
        if not match_found:
            logger.warning(f"No match found for {species}")
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.NO_RESULTS_FOUND,
                message=f"No matching search results found for '{species}'",
                status_code=status.HTTP_404_NOT_FOUND
            )

    def _get_match_link(self, match: dict, name: str) -> str:
        """Return RHS url for plant."""
        id = match.get("id")
        name = name.replace(" ", "-")
        plant_url = f"https://www.rhs.org.uk/plants/{id}/{name}/details"
        return plant_url

    def rhs_plant_search(self, species: str) -> Optional[PlantDetails]:
        """
        Comprehensive plant search and details retrieval.

        Args:
            species (str): Plant species name to search for.

        Returns:
            PlantDetails or None.
        """
        try:
            # Search for plant
            search_results = self.search_rhs_plants(species)

            # Check for match
            match_url = self.find_match(species, search_results)

            # Retrieve plant details
            logger.info("Searching for plant details...")
            return self.get_rhs_details(match_url, species)
        except PlantServiceException:
            raise
        except Exception as e:
            logger.debug(f"Unexpected error in plant search: {e}")
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.PARSING_ERROR,
                message="Failed to process plant details",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                details={"error": str(e)}
            )

    def get_rhs_details(self, url: str, species: str = '') -> Optional[PlantDetails]:
        """
        Retrieve detailed plant information from a specific RHS plant details page.

        Args:
            url (str): The direct URL to the plant's details page on the RHS website.
            species (str, optional): The name of the plant species, for context in error messages.

        Returns:
            Optional[PlantDetails]: Structured plant details if found, None otherwise.

        Raises:
            PlantServiceException: If there are issues accessing or parsing the plant details.
        """
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36'
            }

            try:
                logger.info(f"Requesting {url}")
                response = requests.get(url=url, headers=headers, timeout=10)
                response.encoding = "utf-8"
            except requests.Timeout as e:
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.TIMEOUT_ERROR,
                    message=f"Timed out when attempting to get {url}",
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    details={"error": str(e)}
                )
            except requests.RequestException as e:
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.NETWORK_ERROR,
                    message=f"Failed to access RHS at {url}",
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    details={"error": str(e)}
                )

            logger.info("Extracting soup...")
            soup = BeautifulSoup(response.text, "html.parser")

            # Check if page contains full details or only summary
            logger.info("Looking for lib-plant-details elements...")
            full_details_element = soup.select_one('lib-plant-details-full')
            summary_element = soup.select_one('lib-plant-details-summary')

            if full_details_element:
                logger.info("Found full details element")
                return self._extract_all_details(full_details_element)

            elif summary_element:
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.NO_RESULTS_FOUND,
                    message=f"RHS has no detailed information for '{species}', only a brief summary",
                    status_code=status.HTTP_404_NOT_FOUND
                )

            else:
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.ELEMENT_ERROR,
                    message="Plant details elements not found",
                    status_code=status.HTTP_404_NOT_FOUND
                )

        except PlantServiceException:
            raise
        except Exception as e:
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
            cultivation_tips=self._extract_href_text_field(soup, 'Cultivation'),
            pruning=self._extract_href_text_field(soup, 'Pruning')
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
            scraper = PlantScraper(base_url=settings.RHS_BASE_URL)

            details = await asyncio.to_thread(scraper.rhs_plant_search, plant)

            if details is None:
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.NO_RESULTS_FOUND,
                    message=f"No details found on RHS website for '{plant}'",
                    status_code=status.HTTP_404_NOT_FOUND
                )

            try:
                logger.info(f"RHS details: {details}")
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

