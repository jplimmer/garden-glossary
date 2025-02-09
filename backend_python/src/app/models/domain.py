from dataclasses import dataclass, asdict
from typing import Optional, Dict, List, Any
from fastapi import status
from app.exceptions import PlantServiceException, PlantServiceErrorCode

@dataclass
class Size:
    """
    Dataclass for 'Size' information on plant.

    Attributes:
        height (str): Ultimate height of plant
        spread (str): Ultimate spread of plant
        time_to_height (str): Time taken for plant to reach ultimate height

    Methods:
        to_dict: Convert information into Dict, raise PlantServiceException if error
    """
    height: Optional[str] = None
    spread: Optional[str] = None
    time_to_height: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        try:
            return {k: v for k, v in asdict(self).items() if v is not None}
        except Exception as e:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.PARSING_ERROR,
                message="Failed to convert data class to dictionary",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                details={"class": self.__class__.__name__, "error": str(e)}
            )

@dataclass
class Soil:
    """
    Dataclass for 'Soil' growing conditions for plant.

    Attributes:
        types (List[str]): List of soil types the plant can grow in (e.g. 'Chalk')
        moisture (List[str]): List of descriptors for moisture levels the plant can grow in (e.g. 'Well-drained')
        ph_levels (List[str]): List of pH bands the plant can grow in (e.g. 'Acidic')

    Methods:
        to_dict: Convert information into Dict, raise PlantServiceException if error
    """
    types: List[str]
    moisture: List[str]
    ph_levels: List[str]

    def to_dict(self) -> Dict[str, Any]:
        try:
            return {k: v for k, v in asdict(self).items() if v is not None}
        except Exception as e:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.PARSING_ERROR,
                message="Failed to convert data class to dictionary",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                details={"class": self.__class__.__name__, "error": str(e)}
            )

@dataclass
class Position:
    """
    Dataclass for 'Position' information on plant.

    Attributes:
        sun (str): Type of sun exposure plant should grow in (e.g. 'Full sun')
        aspect (str): Direction of sunlight plant should be exposed to (e.g. 'West-facing')
        exposure (str): 

    Methods:
        to_dict: Convert information into Dict, raise PlantServiceException if error
    """
    sun: Optional[str] = None
    aspect: Optional[str] = None
    exposure: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        try:
            return {k: v for k, v in asdict(self).items() if v is not None}
        except Exception as e:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.PARSING_ERROR,
                message="Failed to convert data class to dictionary",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                details={"class": self.__class__.__name__, "error": str(e)}
            )

@dataclass
class PlantDetails:
    """
    Dataclass containing all detailed information on plant.

    Attributes:
        size (Size): 'Size' object with information on ultimate plant size
        hardiness (str): RHS Hardiness rating and descriptor
        soil (Soil): 'Soil' object with information on soil requirements for plant
        position (Position): 'Position' object with information on plant sunlight and shelter
        cultivation_tips (str): RHS tips on cultivation
        pruning (str): RHS tips on pruning

    Methods:
        to_dict: Convert information into Dict, raise PlantServiceException if error
    """
    size: Optional[Size] = None
    hardiness: Optional[str] = None
    soil: Optional[Soil] = None
    position: Optional[Position] = None
    cultivation_tips: Optional[str] = None
    pruning: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        try:
            return {k: v for k, v in asdict(self).items() if v is not None}
        except Exception as e:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.PARSING_ERROR,
                message="Failed to convert data class to dictionary",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                details={"class": self.__class__.__name__, "error": str(e)}
            )
        
