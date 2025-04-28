"""Service to find key cultivation details about a plant using an LLM."""
from typing import Dict
import uuid
import json
from fastapi import status
from anthropic import AsyncAnthropic, APIStatusError, APIConnectionError, APITimeoutError
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
                "sun": ["Sunlight requirements"]
            }},
            "cultivation_tips": "Brief tips about planting and care",
            "pruning": "Specific pruning instructions",
        }}
        """
    
    async def get_plant_details(self, plant_name: str) -> Dict:        
        request_id = str(uuid.uuid4())
        logger.info(f"Request {request_id} - calling Anthropic API for plant: {plant_name}")

        try:
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
            logger.debug(f"Request {request_id} - Raw response: {response}")

            content_text = response.content[0].text if response.content else ""

            try:
                details = json.loads(content_text)
                self._validate_plant_details(details)
                logger.info(f"Request {request_id} - LLM details: {details}")
                return details
            except json.JSONDecodeError as e:
                logger.error(f"Request {request_id} - Failed to parse JSON response: {e}, content: {content_text[:100]}...")
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.PARSING_ERROR,
                    message="Failed to parse plant details from LLM response",
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
            
        except APIStatusError as e:
            if e.status_code in [401, 403]:
                logger.error(f"Request {request_id} - Anthropic authentication error: {str(e)}")
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.SERVICE_ERROR,
                    message="Authentication error with Anthropic",
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE
                )
            elif e.status_code in [429, 529]:
                logger.error(f"Request {request_id} - Anthropic rate limit or capacity error: {str(e)}")
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.SERVICE_ERROR,
                    message="Anthropic service temporarily unavailable",
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE
                )
            else:
                logger.error(f"Request {request_id} - Anthropic API error: {str(e)}")
                raise PlantServiceException(
                    error_code=PlantServiceErrorCode.SERVICE_ERROR,
                    message="Error retrieving plant details from Anthropic",
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        except APIConnectionError as e:
            logger.error(f"Request {request_id} - Anthropic connection error: {str(e)}")
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.SERVICE_ERROR,
                message="Unable to connect to Anthropic",
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        except APITimeoutError as e:
            logger.error(f"Request {request_id} - Anthropic timeout error: {str(e)}")
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.SERVICE_ERROR,
                message="Anthropic request timed out",
                status_code=status.HTTP_504_GATEWAY_TIMEOUT
            )
        except Exception as e:
            if isinstance(e, PlantServiceException):
                raise
            logger.error(f"Request {request_id} - Unexpected error: {str(e)}", exc_info=True)
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.SERVICE_ERROR,
                message=f"Unexpected error retrieving plant details",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
            )            

    def _validate_plant_details(self, details: Dict) -> None:
        """Validate that the returned JSON has the expected structure."""
        required_fields = ["size", "hardiness", "soil", "position", "cultivation_tips", "pruning"]
        missing_fields = [field for field in required_fields if field not in details]

        if missing_fields:
            logger.warning(f"Missing fields in plant details: {', '.join(missing_fields)}")
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.VALIDATION_ERROR,
                message="Plant details from Anthropic are incomplete",
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY
            )

class PlantDetailsLlmService:
    """
    Service layer for getting plant details from the LLM.
    """
    async def get_plant_details(self, plant_name: str) -> PlantDetails:
        llm_client = PlantAnthropicClient()
        details = await llm_client.get_plant_details(plant_name)
        return PlantDetails(**details)

