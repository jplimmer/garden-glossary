from fastapi import APIRouter, status
from app.models import PlantDetailRequest, PlantDetailResponse
from app.services import PlantDetailsRhsService
import logging

logger = logging.getLogger(__name__)

# Router endpoint
router = APIRouter(
    tags=["garden_glossary"],
)

@router.post(
    "/plant-details-rhs/",
    response_model=PlantDetailResponse,
    summary="Extract key cultivation details about a plant from the RHS website",
    status_code=status.HTTP_200_OK
)
async def plant_details(request: PlantDetailRequest):
    service = PlantDetailsRhsService()
    details = await service.retrieve_plant_details(request.plant)
    return PlantDetailResponse(details=details)

