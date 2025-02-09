from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from enum import Enum

class Organ(str, Enum):
    """Enumeration of possible organs to pass to PlantNet API."""
    leaf = "leaf"
    flower = "flower"
    fruit = "fruit"
    bark = "bark"
    auto = "auto"

class Match(BaseModel):
    """
    Model for individual plant identification matches, to be returned to the frontend.

    Attributes:
        species (str): Name of identified species
        genus (str): Name of identified genus
        score (float): Probability of identification being correct
        commonNames (List[str]): List of common names for identified species 
    """
    species: str
    genus: str
    score: float
    commonNames: List[str]

class PlantIdentificationResponse(BaseModel):
    """
    Response model for 'Plant Identification' service.

    Attributes:
        matches (Dict[int, Match]): List of possible identified matches
    """
    matches: Dict[int, Match]

    class Config:
        json_schema_extra = {
            "example": {
                "status_code": 200,
                "matches": {
                    0: {
                        'species': 'Tulipa gesneriana', 
                        'genus': 'Tulipa', 
                        'score': 0.82973, 
                        'commonNames': ["Didier's tulip", 'Garden tulip', 'Tulip']
                    }, 
                    1: {
                        'species': 'Tulipa kaufmanniana', 
                        'genus': 'Tulipa', 
                        'score': 0.02704, 
                        'commonNames': ['Water-lily tulip', "Kaufmann's Tulip"]
                    }, 
                    2: {
                        'species': 'Tulipa fosteriana', 
                        'genus': 'Tulipa', 
                        'score': 0.01164, 
                        'commonNames': []
                    }
                }
            }
        }

class PlantDetailRequest(BaseModel):
    """
    Request model for 'Plant Details' endpoint input validation.

    Attributes:
        field (str): Name of plant species 
    """
    plant: str = Field(..., min_length=1, description="Name of the plant species to search for")

    class Config:
        json_schema_extra = {
            "example": {
                "plant": "tulipa gesneriana"
            }
        }

class PlantDetailResponse(BaseModel):
    """
    Response model for 'Plant Details' services.

    Attributes:
        details (Dict[str, Any]): Dictionary of detailed information on the plant.
    """
    details: Dict[str, Any]

    class Config:
        json_schema_extra = {
            "example": {
                "details": {
                    "size": {
                        "height": "0.1-0.5 metres",
                        "spread": "0.1-0.5 metres",
                        "time_to_height": "1 year"
                    },
                    "hardiness": "H6: hardy in all of UK and northern Europe (-20 to -15)",
                    "soil": {
                        "types": ["Chalk", "Clay", "Loam", "Sand"],
                        "moisture": ["Moist but well-drained"],
                        "ph_levels": ["Acid"]
                    },
                    "position": {
                        "sun": "Full sun",
                        "aspect": "South-facing or West-facing",
                        "exposure": "Sheltered"
                    },
                    "cultivation_tips": "Plant in autumn, at a depth of...",
                    "pruning": "Deadhead after flowering and remove fallen petals."
                }
            }
        }

class ErrorResponse(BaseModel):
    """
    Response model for errors in API services, to be returned to the frontend in a JSONResponse.
    """
    error_code: str
    message: str
    details: Optional[Dict[str, Any]] = None

