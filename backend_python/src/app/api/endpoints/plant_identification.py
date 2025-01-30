import os
import uuid
from fastapi import APIRouter, File, Form, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from app.services import PlantIdentificationService
from app.config import settings
import logging
logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/identify-plant/")
async def identify_plant(
    file: UploadFile = File(...),
    organ: str = Form(...)
):
    
    try:
        # Ensure uploads directory exists
        os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
        
        # Generate a unique filename
        file_extension = file.filename.split('.')[-1]
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_location = os.path.join(settings.UPLOAD_DIR, unique_filename)
        
        # Save the uploaded file
        with open(file_location, "wb+") as file_object:
            file_object.write(await file.read())
        
        try:
            # Identify plant using PlantNet API
            service = PlantIdentificationService()
            matches = service.identify_plant(file_location, organ)
            
            # Remove the file after processing
            os.remove(file_location)

            # Return JSON
            return JSONResponse(content={"matches": matches})
        
        except Exception as processing_error:
            # If processing fails, keep the file for debugging
            return {
                "error": f"Image processing failed: {str(processing_error)}",
                "file_location": file_location
            }
    
    except Exception as e:
        # Handle file upload errors
        raise HTTPException(status_code=500, detail=f"File upload failed: {str(e)}")

