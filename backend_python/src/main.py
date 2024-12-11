from dotenv import load_dotenv
import os
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import uuid

import requests
import json

from selenium import webdriver

import logging

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s"
)


# Get Pl@ntNet API key from environment variables
load_dotenv()
API_KEY = os.getenv("API_KEY")
PROJECT = "all"
api_endpoint = f"https://my-api.plantnet.org/v2/identify/{PROJECT}?api-key={API_KEY}"


# Create FastAPI instance
app = FastAPI()

# Add CORS middleware to allow requests from mobile app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)



# image_path = "C:\\Users\\james\\OneDrive\\Documents\\Coding\\Projects\\garden-glossary\\backend_python\\images\\test_image.JPEG"
# image_path = "..\\images\\test_image.jpeg"

@app.post("/process-image/")
async def process_image(file: UploadFile = File(...)):
    try:
        # Ensure uploads directory exists
        logging.info("Entered first try loop")
        os.makedirs("uploads", exist_ok=True)
        
        # Generate a unique filename
        file_extension = file.filename.split('.')[-1]
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_location = os.path.join("uploads", unique_filename)
        
        # Save the uploaded file
        with open(file_location, "wb+") as file_object:
            file_object.write(await file.read())
        
        try:
            # Call your existing image processing function
            genus, score = plantnet_identification(file_location)
            
            # Optional: Remove the file after processing if you don't need to keep it
            os.remove(file_location)
            
            return {
                "genus": genus,
                "score": score
            }
        
        except Exception as processing_error:
            # If processing fails, keep the file for debugging
            return {
                "error": f"Image processing failed: {str(processing_error)}",
                "file_location": file_location
            }
    
    except Exception as e:
        # Handle file upload errors
        raise HTTPException(status_code=500, detail=f"File upload failed: {str(e)}")

def plantnet_identification(image_path):  
    logging.info("Entered plantnet_identification() function")
    image_data = open(image_path, 'rb')
    
    data = { 
        'organs': ['flower'] # to be updated from frontend
    }

    files = [
        ('images', ((image_path), (image_data)))
    ]

    req = requests.Request('POST', url=api_endpoint, files=files, data=data)
    prepared = req.prepare()

    s = requests.Session()
    response = s.send(prepared)
    json_result = json.loads(response.text) # is this necessary?
    results = json_result['results']

    logging.info(response.status_code)
    logging.info(results[0])

    genus = results[0]['species']['genus']['scientificNameWithoutAuthor']
    logging.info(genus)

    score = results[0]['score']
    logging.info(score)

    return genus, score


if __name__ == "__main__":
    # Run the server
    uvicorn.run(app, host="0.0.0.0", port=8000)


# Scrape RHS
# rhs_url = f"https://www.rhs.org.uk/plants/{genus}"
# driver = webdriver.Chrome()
# driver.maximize_window()
# driver.get(rhs_url)