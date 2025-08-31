import logging

from fastapi import APIRouter, status

from app.models import PlantDetailRequest, PlantDetailResponse
from app.services import PlantDetailsLlmService

logger = logging.getLogger(__name__)

# Router endpoint
router = APIRouter(tags=["plant_details"])


@router.post(
    "/plant-details-llm/",
    response_model=PlantDetailResponse,
    summary="Use Anthropic LLM to find key cultivation details about a plant",
    status_code=status.HTTP_200_OK,
)
async def plant_details(request: PlantDetailRequest) -> PlantDetailResponse:
    service = PlantDetailsLlmService()
    details = await service.get_plant_details(request.plant)
    return PlantDetailResponse(**details.to_dict())
