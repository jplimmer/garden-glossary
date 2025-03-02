"""Service to find key cultivation details about a plant using an LLM."""

from typing import Dict
import json
from fastapi import status
from anthropic import AsyncAnthropic
from app.config import settings
from app.exceptions import PlantServiceException, PlantServiceErrorCode
from app.models import PlantDetails
import logging

logger = logging.getLogger(__name__)

class PlantAnthropicClient:
    def __init__(self, model: str= "claude-3-haiku-20240307"):
        self.client = AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
        self.model = model

    def get_llm_prompt(self, plant_name: str) -> str:
        return f"""You are a gardening expert. I need detailed information about {plant_name}.
        Return only a JSON object with the exact structure shown below, no other text or explanations.
        The JSON must include all fields shown:

        {{
            "size": {{
                "height": "Height range in metres",
                "spread": "Spread range in metres",
                "time_to_height": "Time to reach full height"
            }},
            "hardiness": "Standard hardiness rating (e.g., H6: hardy in all of UK)",
            "soil": {{
                "moisture": ["Soil moisture requirements"],
                "ph_levels": ["Soil pH preferences"],
                "types": ["Compatible soil types"]
            }},
            "position": {{
                "aspect": "Preferred facing direction",
                "exposure": "Level of exposure needed",
                "sun": "Sunlight requirements"
            }},
            "cultivation_tips": "Brief tips about planting and care",
            "pruning": "Specific pruning instructions",
        }}
        """
    
    async def get_plant_details(self, plant_name: str) -> Dict:        
        try:
            logging.info(f"Calling Anthropic API for plant: {plant_name}")
            response = await self.client.messages.create(
                model=self.model,
                max_tokens=1024,
                temperature=0.2,
                system="You are a gardening expert. Provide accurate plant information in JSON format only.",
                messages=[
                    {"role": "user",
                     "content": self.get_llm_prompt(plant_name)}
                ]
            )
            details = json.loads(response.content[0].text)
            logging.info(f"LLM details: {details}")
            return details
        except Exception as e:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.SERVICE_ERROR,
                message=f"Error getting plant details from LLM: {str(e)}",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
            )            

class PlantDetailsLlmService:
    """
    Service layer for getting plant details from the LLM.
    """
    async def get_plant_details(self, plant_name: str) -> PlantDetails:
        llm_client = PlantAnthropicClient()
        details = await llm_client.get_plant_details(plant_name)
        return PlantDetails(**details)

