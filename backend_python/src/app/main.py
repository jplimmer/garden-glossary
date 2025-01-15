from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import plant_identification, plant_details
from app.core.logging import setup_logging
import uvicorn

def create_application() -> FastAPI:
    app = FastAPI()
    
    # Add CORS middleware to allow requests from mobile app
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Allows all origins
        allow_credentials=True,
        allow_methods=["*"],  # Allows all methods
        allow_headers=["*"],  # Allows all headers
    )

    # Set-up logging
    setup_logging()

    # Include routers
    app.include_router(plant_identification.router, prefix="/api/v1")
    app.include_router(plant_details.router, prefix="/api/v1")

    return app

app = create_application()

if __name__ == "__main__":
    # Run the server
    uvicorn.run(app, host="0.0.0.0", port=8000)

