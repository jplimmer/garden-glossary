from dotenv import load_dotenv
import os

import requests
import json
import selenium
from selenium import webdriver

load_dotenv()

API_KEY = os.getenv("API_KEY")
PROJECT = "all"
api_endpoint = f"https://my-api.plantnet.org/v2/identify/{PROJECT}?api-key={API_KEY}"


image_path = "C:\\Users\\james\\OneDrive\\Documents\\Coding\\Projects\\garden-glossary\\backend_python\\images\\test_image.JPEG"
# image_path = "..\\images\\test_image.jpeg"
image_data = open(image_path, 'rb')

data = {
    'organs': ['flower']
}

files = [
    ('images', ((image_path), (image_data)))
]

req = requests.Request('POST', url=api_endpoint, files=files, data=data)
prepared = req.prepare()

s = requests.Session()
response = s.send(prepared)
json_result = json.loads(response.text)
results = json_result['results']

print(response.status_code)
print(results[0])

genus = results[0]['species']['genus']['scientificNameWithoutAuthor']
print(genus)

# Scrape RHS
# rhs_url = f"https://www.rhs.org.uk/plants/{genus}"
# driver = webdriver.Chrome()
# driver.maximize_window()
# driver.get(rhs_url)