from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.models import ErrorResponse
from app.api.endpoints import plant_identification, plant_details_rhs
from app.exceptions import PlantServiceException
import logging
from app.core.logging import setup_logging
import uvicorn

def create_application() -> FastAPI:
    # Set-up logging
    setup_logging()
    logger = logging.getLogger(__name__)

    app = FastAPI(
        title="Garden Glossary API",
        description="""
        # 🌱 API service for identifying a plant from an image and providing cultivation details.
        
        ## Features:
        * identify-plant: Passes an uploaded image and 'organ' to the PlantNet API, to return the 3 most likely species matches.
        * plant-details-rhs: Searches RHS website for requested plant species and returns key cultivation details.
        * plant-details-llm: Fallback service if plant-details-rhs fails - calls ChatGPT API to return plant details in same style and format as plant-details-rhs service.
        """
    )
    
    # Add CORS middleware to allow requests from mobile app
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Register exception handler
    @app.exception_handler(PlantServiceException)
    async def plant_service_exception_handler(request: Request, exc: PlantServiceException):
        logger.error(f"PlantServiceException:  {exc.error_code.value} - {exc.message}")
        return JSONResponse(
            status_code=exc.status_code,
            content=ErrorResponse(
                error_code=exc.error_code,
                message=exc.message,
                details=exc.details
            ).model_dump()
        )
 
    # Include routers
    app.include_router(plant_identification.router, prefix="/api/v1")
    app.include_router(plant_details_rhs.router, prefix="/api/v1")

    return app

app = create_application()

if __name__ == "__main__":
    # Run the server
    uvicorn.run(app, host="0.0.0.0", port=8000)

