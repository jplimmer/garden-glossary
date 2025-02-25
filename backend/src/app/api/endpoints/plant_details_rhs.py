from fastapi import APIRouter, status
from app.models import PlantDetailRequest, PlantDetailResponse
from app.services import PlantDetailsRhsService
import logging

logger = logging.getLogger(__name__)

# Router endpoint
router = APIRouter(
    tags=["plant_details"],
)

@router.post(
    "/plant-details-rhs/",
    response_model=PlantDetailResponse,
    summary="Extract key cultivation details about a plant from the RHS website",
    status_code=status.HTTP_200_OK
)
async def plant_details(plant_request: PlantDetailRequest) -> PlantDetailResponse:
    service = PlantDetailsRhsService()
    details = await service.retrieve_plant_details(plant_request.plant)    
    return PlantDetailResponse(**details.to_dict())

