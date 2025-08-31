import logging
import os
import uuid

from fastapi import APIRouter, Depends, File, Form, UploadFile, status

from app.config import get_settings
from app.models import Organ, PlantIdentificationResponse
from app.services import PlantIdentificationService

logger = logging.getLogger(__name__)

# Router endpoint
router = APIRouter(
    tags=["plant_identification"],
)

@router.post(
    "/identify-plant/",
    response_model=PlantIdentificationResponse,
    summary="Identify plant species based on image upload, using the PlantNet API",
    status_code=status.HTTP_200_OK
)
async def identify_plant(
    file: UploadFile = File(...),
    organ: Organ = Form(...),
    settings = Depends(get_settings)
):
    # Ensure uploads directory exists
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)

    # Generate a unique filename
    file_extension = file.filename.split('.')[-1]
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    file_location = os.path.join(settings.UPLOAD_DIR, unique_filename)

    file_saved = False
    try:
        # Save the uploaded file
        logger.debug('Saving file...')
        with open(file_location, "wb+") as file_object:
            file_object.write(await file.read())
        file_saved = True
        logger.debug('File saved.')

        # Identify plant using PlantNet API
        service = PlantIdentificationService()
        result = service.identify_plant(file_location, organ)

        # Return response based on service result
        return PlantIdentificationResponse(matches=result['matches'])

    finally:
        # Remove file after processing
        if file_saved and os.path.exists(file_location):
            try:
                os.remove(file_location)
            except Exception as e:
                logger.error(f"Failed to remove temporary file: {e}")

