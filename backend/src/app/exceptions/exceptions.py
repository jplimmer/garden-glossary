"""
Exceptions module for plant service operations.

This module contains all custom exceptions and error codes used across the plant services, 
providing a centralised location for error handling and documentation.
"""

from enum import Enum
from typing import Optional, Dict, Any
from fastapi import status

class PlantServiceErrorCode(Enum):
    """Enumeration of possible error codes."""
    
    SERVICE_INITIALIZATION = "SERVICE_INIT_001"
    BROWSER_ERROR = "BROWSER_002"
    COOKIE_CONSENT_FAILED = "COOKIE_003"
    NO_RESULTS_FOUND = "SEARCH_004"
    PARSING_ERROR = "PARSE_005"
    NETWORK_ERROR = "NETWORK_006"
    VALIDATION_ERROR = "VALIDATION_007"
    TIMEOUT_ERROR = "TIMEOUT_008"
    SERVICE_ERROR = "SERVICE_009"
    ELEMENT_ERROR = "ELEMENT_010"

class PlantServiceException(Exception):
    """
    Custom exception for handling errors in plant services.

    Attributes:
        error_code (PlantServiceErrorCode): The error code enum value
        message (str): Summary error message
        status_code (int): HTTP status code
        details (Optional[Dict[str, Any]]): Detailed error message
    """
    def __init__(
        self,
        error_code: PlantServiceErrorCode,
        message: str,
        status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR,
        details: Optional[Dict[str, Any]] = None
    ):
        self.error_code = error_code
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        super().__init__(self.message)

    def __str__(self):
        return f"{self.error_code.value}: {self.message}"

