import os
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import logging

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from mangum import Mangum

from app.api.endpoints import plant_details_llm, plant_details_rhs, plant_identification
from app.config import settings
from app.exceptions import PlantServiceException
from app.models import ErrorResponse


def create_application() -> FastAPI:
    # Configure logging globally
    settings.setup_logging()

    # Create loggers with possible Lambda context
    context_logger = logging.getLogger(__name__)

    app = FastAPI(
        title="Garden Glossary API",
        description="""
        # API service for identifying a plant from an image and
        # providing cultivation details.

        ## Features:
        * identify-plant: Passes an uploaded image and 'organ' to the PlantNet API,
            to return the 3 most likely species matches.
        * plant-details-rhs: Searches RHS website for requested plant species and
            returns key cultivation details.
        * plant-details-llm: Fallback service if plant-details-rhs fails -
            calls Anthropic API to return plant details in same style and
            format as plant-details-rhs service.
        """,
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
    async def plant_service_exception_handler(
        request: Request, exc: PlantServiceException
    ):
        context_logger.error(
            f"PlantServiceException:  {exc.error_code.value} - {exc.message}",
            extra={"error_code": exc.error_code, "details": exc.details},
        )
        return JSONResponse(
            status_code=exc.status_code,
            content=ErrorResponse(
                error_code=exc.error_code.value,
                message=exc.message,
                details=exc.details,
            ).model_dump(),
        )

    # Include routers
    app.include_router(plant_identification.router, prefix="/api/v1")
    app.include_router(plant_details_rhs.router, prefix="/api/v1")
    app.include_router(plant_details_llm.router, prefix="/api/v1")

    # Add health-check endpoint
    @app.get("/health", tags=["api_health"])
    async def health_check():
        context_logger.info("Health check endpoint called")
        return {"status": "healthy"}

    # Add environment endpoint:
    @app.get("/env", tags=["api_health"])
    async def env_check():
        env_info = {
            "AWS_EXECUTION_ENV": os.getenv("AWS_EXECUTION_ENV"),
            "DOCKER_ENVIRONMENT": os.getenv("DOCKER_ENVIRONMENT"),
        }
        context_logger.info("Environment information retrieved", extra=env_info)
        return env_info

    return app


# Create FastAPI application
app = create_application()

# Create handler for AWS Lambda
handler = Mangum(app)

if __name__ == "__main__":
    # Run the server if executed directly (local development)
    import uvicorn

    logger = logging.getLogger(__name__)
    logger.info("Starting local development server")
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port, reload=True)
