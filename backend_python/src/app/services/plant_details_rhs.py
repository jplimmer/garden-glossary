import asyncio
from fastapi import HTTPException
from dataclasses import dataclass, asdict
from typing import Optional, List, Dict, Any
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, ElementNotInteractableException
from bs4 import BeautifulSoup
from contextlib import contextmanager
import logging
logger = logging.getLogger(__name__)

@dataclass
class Size:
    height: Optional[str] = None
    spread: Optional[str] = None
    time_to_height: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {k: v for k, v in asdict(self).items() if v is not None}

@dataclass
class Soil:
    types: List[str]
    moisture: List[str]
    ph_levels: List[str]

    def to_dict(self) -> Dict[str, Any]:
        return {k: v for k, v in asdict(self).items() if v is not None}

@dataclass
class Position:
    sun: Optional[str] = None
    aspect: Optional[str] = None
    exposure: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {k: v for k, v in asdict(self).items() if v is not None}

@dataclass
class PlantDetails:
    size: Optional[Size] = None
    hardiness: Optional[str] = None
    soil: Optional[Soil] = None
    position: Optional[Position] = None
    cultivation_tips: Optional[str] = None
    pruning: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {k: v for k, v in asdict(self).items() if v is not None}

class CookieConsentHandler:
    BUTTON_CONFIGS = [
        {"by": By.ID, "value": "onetrust-accept-btn-handler"},
        {"by": By.CLASS_NAME, "value": "onetrust-close-btn-handler"},
        {"by": By.CSS_SELECTOR, "value": "button[aria-label='Close']"}
    ]

    @classmethod
    def handle(cls, driver: webdriver.Chrome, timeout: int=3) -> bool:
        for config in cls.BUTTON_CONFIGS:
            try:
                button = WebDriverWait(driver, timeout).until(
                    EC.element_to_be_clickable((config["by"], config["value"]))
                )
                button.click()
                logger.info(f"Successfully clicked cookie consent button: {config['value']}")
                return True
            except (TimeoutException, ElementNotInteractableException):
                logger.debug(f"Could not find cookie button: {config['value']}")
                continue
        
        logger.warning("Could not handle cookie consent - no matching buttons found")
        return False

@contextmanager
def create_driver():
    driver = webdriver.Chrome()
    try:
        driver.maximize_window()
        yield driver
    finally:
        driver.quit()

class PlantScraper:
    def __init__(self, base_url: str):
        self.base_url = base_url

    def _find_plant_details(self, soup: BeautifulSoup, selector: str) -> Optional[BeautifulSoup]:
        panel = soup.find('h6', string=selector)
        return panel.find_parent('div', class_='plant-attributes__panel') if panel else None
    
    def _extract_size(self, soup: BeautifulSoup) -> Optional[Size]:
        size_panel = self._find_plant_details(soup, 'Size')
        if not size_panel:
            return None
        
        return Size(
            height = self._extract_field(size_panel, 'Ultimate height'),
            spread = self._extract_field(size_panel, 'Ultimate spread'),
            time_to_height = self._extract_field(size_panel, 'Time to ultimate height'),
        )
    
    def _extract_hardiness(self, soup: BeautifulSoup) -> Optional[str]:
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
        pruning_h5 = soup.find('h5', string='Pruning')
        if not pruning_h5:
            return None
        
        pruning_span = pruning_h5.find_parent('span')
        if not pruning_span:
            return None
        
        p_tag = pruning_span.find('p')
        return p_tag.text.strip() if p_tag and p_tag.text else None
    
    def _extract_field(self, panel: BeautifulSoup, field_name: str) -> Optional[str]:
        field_div = panel.find('h6', string=field_name)
        if field_div:
            parent_div = field_div.find_parent('div', class_='flag__body')
            return parent_div.contents[-1].strip() if parent_div else None
        return None
    
    def get_plant_details(self, species: str) -> Optional[PlantDetails]:
        species_query = species.replace(" ", "%20").lower()
        url = f"{self.base_url}{species_query}"

        with create_driver() as driver:
            try:
                driver.get(url)
                if not CookieConsentHandler.handle(driver):
                    raise Exception("Failed to handle cookie consent")
                
                # Scroll to bottom and find matching result
                driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                wait = WebDriverWait(driver, 5)

                search_results = wait.until(
                    EC.presence_of_all_elements_located((
                        By.CSS_SELECTOR, 'app-plant-search-list a.u-faux-block-link__overlay'
                    ))
                )

                match_found = False
                for result in search_results:
                    if species.lower() == result.get_attribute('innerText').strip().lower():
                        result.click()
                        match_found = True
                        break
                
                if not match_found:
                    logger.warning(f"No match found for species: {species}")
                    return None
                
                # Extract details
                driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                content = wait.until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, 'lib-plant-details-full.ng-star-inserted'))
                )

                soup = BeautifulSoup(driver.page_source, "lxml")
                return self._extract_all_details(soup)
            
            except Exception as e:
                logger.error(f"Error scraping plant details: {str(e)}")
                return None
            
    def _extract_all_details(self, soup: BeautifulSoup) -> PlantDetails:
        return PlantDetails(
            size=self._extract_size(soup),
            hardiness=self._extract_hardiness(soup),
            soil=self._extract_soil(soup),
            position=self._extract_position(soup),
            cultivation_tips=self._extract_cultivation_tips(soup),
            pruning=self._extract_pruning(soup)
        )


class PlantDetailsRhsService:
    @staticmethod
    async def retrieve_plant_details(plant: str) -> dict:
        try:
            scraper = PlantScraper(base_url='https://www.rhs.org.uk/plants/search-results?query=')
            details = await asyncio.to_thread(scraper.get_plant_details, plant)
            
            if details is None:
                raise HTTPException(status_code=404, detail="Plant details not found")
            
            return {
                'size': details.size.to_dict() if details.size else None,
                'hardiness': details.hardiness,
                'soil': details.soil.to_dict() if details.soil else None,
                'position': details.position.to_dict() if details.position else None,
                'cultivation_tips': details.cultivation_tips,
                'pruning': details.pruning,
            }

        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))
    
