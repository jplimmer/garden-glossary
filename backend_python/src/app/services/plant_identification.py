import requests
import json
from app.config import settings
import logging

class PlantIdentificationService:
    @staticmethod
    def identify_plant(image_path: str, organ: str) -> dict:
        try:
            with open(image_path, 'rb') as image_data:
                files = [('images', ((image_path), (image_data)))]
                data = {'organs': [organ]}

                response = requests.post(
                    url=settings.API_ENDPOINT, 
                    files=files, 
                    data=data
                )
                response.raise_for_status()

                response_data = response.json()
                results = response_data.get('results', [])

        except requests.RequestException as e:
            logging.error(f"HTTP request failed: {e}")
            return {}
        except json.JSONDecodeError:
            logging.error("Failed to parse JSON response.")
            return {}

        matches = {
            i: {
                'genus': result['species']['genus']['scientificNameWithoutAuthor'],
                'score': result['score'],
                'commonNames': result['species']['commonNames']
            }
            for i, result in enumerate(results)
        }

        logging.info(f"Matches found: {len(matches)}")
        return matches
    
    