"""Service to identify plant species based on uploaded image, using the PlantNet API."""

import json
import logging
import os

import requests
from fastapi import status

from app.config import settings
from app.exceptions import PlantServiceErrorCode, PlantServiceException
from app.models import Organ

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
            with open(image_path, "rb") as image_data:
                file_header = image_data.read(10)
                logger.debug(f"File header: {file_header.hex()}")
                image_data.seek(0)

                files = [("images", (image_path, image_data, "image/jpeg"))]
                data = {"organs": [organ.value]}

                logger.debug(f"Files: {files}")
                logger.debug(f"File size: {os.path.getsize(image_path) / 1024} KB")

                logger.info("Calling PlantNet API...")
                response = requests.post(
                    url=settings.PLANTNET_ENDPOINT, files=files, data=data
                )
                logger.debug(f"Response: {response}")

                # If plant identified, return matches data
                if response.status_code == 200:
                    response_data = response.json()
                    results = response_data.get("results", [])

                    matches = {
                        i: {
                            "species": result.get("species", {}).get(
                                "scientificNameWithoutAuthor", ""
                            ),
                            "genus": result.get("species", {})
                            .get("genus", {})
                            .get("scientificNameWithoutAuthor", ""),
                            "score": result.get("score", 0.0),
                            "commonNames": result.get("species", {}).get(
                                "commonNames", []
                            ),
                            "imageUrls": PlantIdentificationService._extract_image_urls(
                                result["images"], "m", 3
                            ),
                        }
                        for i, result in enumerate(results)
                    }

                    logger.info(f"PlantNet matches: {matches}")
                    return {"matches": matches}

                # Handle 'Species Not Found'
                elif response.status_code == 404:
                    raise PlantServiceException(
                        error_code=PlantServiceErrorCode.NO_RESULTS_FOUND,
                        message="No matching species found",
                        status_code=status.HTTP_404_NOT_FOUND,
                    )
                # Handle 'Too Many Requests'
                elif response.status_code == 429:
                    raise PlantServiceException(
                        error_code=PlantServiceErrorCode.SERVICE_ERROR,
                        message="Rate limit exceeded",
                        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    )
                # Handle other error codes
                else:
                    raise PlantServiceException(
                        error_code=PlantServiceErrorCode.SERVICE_ERROR,
                        message=f"Unexpected error occurred: {response.status_code}",
                        status_code=response.status_code,
                    )

        except requests.RequestException as e:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.NETWORK_ERROR,
                message=str(e),
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
        except json.JSONDecodeError:
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.PARSING_ERROR,
                message="Invalid response format",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
        except Exception as e:
            if isinstance(e, PlantServiceException):
                raise
            raise PlantServiceException(
                error_code=PlantServiceErrorCode.SERVICE_ERROR,
                message=str(e),
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    @staticmethod
    def _extract_image_urls(
        images: list, size: str = "s", max_results: int = None
    ) -> list:
        """
        Extracts image URLs of specified size from the PlantNet API response.

        Args:
            images (list): List of image objects from the PlantNet API response.
            size (str): Size of image URLs to extract ("o", "m" or "s").
            max_results (int, optional): Maximum number of URLs to return. If None, returns all URLs.

        Returns:
            list: List of image URLs, limited by the max_result parameter if specified.
        """
        image_urls = []
        for image in images:
            if image.get("url", {}).get(size):
                image_urls.append(image["url"][size])
                if max_results is not None and len(image_urls) >= max_results:
                    break
        return image_urls
