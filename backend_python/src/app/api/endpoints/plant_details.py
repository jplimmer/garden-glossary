from fastapi import APIRouter
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from app.services import PlantDetailsService
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()

class PlantRequest(BaseModel):
    plant: str

@router.post("/plant-details/")
async def plant_details(request: PlantRequest):
    service = PlantDetailsService()
    details = await service.retrieve_plant_details(request.plant)
    logger.info(f'details: {details}')

    return JSONResponse(
        content={'details': details},
        media_type='application/json',
        )

