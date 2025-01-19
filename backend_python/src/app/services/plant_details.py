import asyncio

class PlantDetailsService:
    @staticmethod
    async def retrieve_plant_details(plant: str) -> dict:
        await asyncio.sleep(3)
        
        plant_details = {'plant': plant,
                         'exposure': 'exposure details',
                         'soilType': 'soil type details',
                         'hardiness': 'hardiness score',
                         'lifeCycle': 'lifecycle details',
                         'plantSize': 'plant size details'
                         }

        return plant_details 

