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
        imageUrls (List[str]): List of URLs for images of identified species
    """
    species: str
    genus: str
    score: float
    commonNames: List[str]
    imageUrls: List[str]

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
                        'commonNames': ["Didier's tulip", 'Garden tulip', 'Tulip'],
                        'imageUrls': [
                            'https://bs.plantnet.org/image/s/85a776b7862898225597accc0d232eb3f9cc56b3',
                            'https://bs.plantnet.org/image/s/f0abf2717be1b13e35c0f4f25c7e1990f4539dac',
                            'https://bs.plantnet.org/image/s/8e11ba4efc2223273ce96551ee8a5565c3c9b498'
                        ]
                    }, 
                    1: {
                        'species': 'Tulipa kaufmanniana', 
                        'genus': 'Tulipa', 
                        'score': 0.02704, 
                        'commonNames': ['Water-lily tulip', "Kaufmann's Tulip"],
                        'imageUrls': []
                    }, 
                    2: {
                        'species': 'Tulipa fosteriana', 
                        'genus': 'Tulipa', 
                        'score': 0.01164, 
                        'commonNames': [],
                        'imageUrls': ['https://bs.plantnet.org/image/s/e161956316b0476b0ade94784a87d8c7e8018844']
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

class Size(BaseModel):
    height: Optional[str] = Field(None, description="Ultimate height of plant")
    spread: Optional[str] = Field(None, description="Ultimate spread of plant")
    time_to_height: Optional[str] = Field(None, description="Time taken for plant to reach ultimate height")

class Soil(BaseModel):
    types: List[str]
    moisture: List[str]
    ph_levels: List[str]

class Position(BaseModel):
    sun: Optional[str] = Field(None, description="Sunlight requirements for plant")
    aspect: Optional[str] = Field(None, description="Direction of sunlight plant should be exposed to")
    exposure: Optional[str] = Field(None, description="Shelter requirements for plant")

class PlantDetailResponse(BaseModel):
    """
    Response model for 'Plant Details' services.

    Attributes:
        size (Size): 'Size' object with information on ultimate plant size
        hardiness (str): RHS Hardiness rating and descriptor
        soil (Soil): 'Soil' object with information on soil requirements for plant
        position (Position): 'Position' object with information on plant sunlight and shelter
        cultivation_tips (str): tips on cultivation
        pruning (str): tips on pruning

    """
    size: Size
    hardiness: str
    soil: Soil
    position: Position
    cultivation_tips: str
    pruning: str

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

