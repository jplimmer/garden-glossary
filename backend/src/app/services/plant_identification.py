"""Service to identify plant species based on uploaded image, using the PlantNet API."""

import requests
import json
from fastapi import status
from app.models import Organ
from app.exceptions import PlantServiceErrorCode, PlantServiceException
from app.config import settings
import logging

logger = logging.getLogger(__name__)

class PlantIdentificationService:
    @staticmethod
    def identify_plant(image_path: str, organ: Organ) -> dict:
        """
        Calls the PlantNet API to identify the plant.

        Args:
            image_path (str): Path for image to be uploaded
            organ (Organ): Organ type to be passed to PlantNet API.
        
        Returns:
            matches (dict): 3 most likely plants that match the image.

        Raises:
            PlantServiceException: If PlantNet cannot identify the species, or the service encounters an issue.     
        """
        try:
            with open(image_path, 'rb') as image_data:
                files = [('images', ((image_path), (image_data)))]
                data = {'organs': [organ.value]}

                response = requests.post(
                    url=settings.API_ENDPOINT, 
                    files=files, 
                    data=data
                )

                # If plant identified, return matches data
                if response.status_code == 200:
                    response_data = response.json()
                    results = response_data.get('results', [])

                    matches = {
                        i: {
                            'species': result['species']['scientificNameWithoutAuthor'],
                            'genus': result['species']['genus']['scientificNameWithoutAuthor'],
                            'score': result['score'],
                            'commonNames': result['species']['commonNames']
                        }
                        for i, result in enumerate(results)
                    }

                    return {'matches': matches}
                
                # Handle 'Species Not Found'
                elif response.status_code == 404:
                    raise PlantServiceException(
                        error_code=PlantServiceErrorCode.NO_RESULTS_FOUND,
                        message="No matching species found",
                        status_code=status.HTTP_404_NOT_FOUND
                    )
                # Handle 'Too Many Requests'
                elif response.status_code == 429:
                    raise PlantServiceException(
                        error_code=PlantServiceErrorCode.SERVICE_ERROR,
                        message="Rate limit exceeded",
                        status_code=status.HTTP_429_TOO_MANY_REQUESTS
                    )
                # Handle other error codes
                else:
                    raise PlantServiceException(
                        error_code=PlantServiceErrorCode.SERVICE_ERROR,
                        message=f"Unexpected error occurred: {response.status_code}",
                        status_code=response.status_code
                    )

        except requests.RequestException as e:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.NETWORK_ERROR,
                message=str(e),
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        except json.JSONDecodeError:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.PARSING_ERROR,
                message="Invalid response format",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        except Exception as e:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.SERVICE_ERROR,
                message=str(e),
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    