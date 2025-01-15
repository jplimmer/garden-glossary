from fastapi import APIRouter
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from app.services import PlantDetailsService

router = APIRouter()

class PlantRequest(BaseModel):
    plant: str

@router.post("/plant-details/")
async def plant_details(request: PlantRequest):
    service = PlantDetailsService()
    details = await service.retrieve_plant_details(request.plant)

    return JSONResponse(content={'details': details})

