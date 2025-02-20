import os
import uuid
from fastapi import APIRouter, File, Form, UploadFile, status
from app.models import Organ, PlantIdentificationResponse
from app.services import PlantIdentificationService
from app.config import settings
import logging

logger = logging.getLogger(__name__)

# Router endpoint
router = APIRouter(
    tags=["garden_glossary"],
)

@router.post(
    "/identify-plant/",
    response_model=PlantIdentificationResponse,
    summary="Identify plant species based on image upload, using the PlantNet API",
    status_code=status.HTTP_200_OK
)
async def identify_plant(
    file: UploadFile = File(...),
    organ: Organ = Form(...)
):
    # Ensure uploads directory exists
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    
    # Generate a unique filename
    file_extension = file.filename.split('.')[-1]
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    file_location = os.path.join(settings.UPLOAD_DIR, unique_filename)

    try:        
        # Save the uploaded file
        with open(file_location, "wb+") as file_object:
            file_object.write(await file.read())
        
        # Identify plant using PlantNet API
        service = PlantIdentificationService()
        result = service.identify_plant(file_location, organ)
        
        # Return response based on service result
        return PlantIdentificationResponse(matches=result['matches'])
                
    finally:
        # Remove file after processing
        if os.path.exists(file_location):
            os.remove(file_location)

