import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    PLANTNET_API_KEY: str = os.getenv("PLANTNET_API_KEY")
    ANTHROPIC_API_KEY: str = os.getenv("ANTHROPIC_API_KEY")
    PROJECT: str = "all"
    NUM_RESULTS: int = 3
    SIMSEARCH: bool = True
    UPLOAD_DIR: str = "uploads"

    # Define API_ENDPOINT dynamically so it updates if other settings change
    @property
    def API_ENDPOINT(self) -> str:
        return f"https://my-api.plantnet.org/v2/identify/{self.PROJECT}?api-key={self.PLANTNET_API_KEY}&nb-results={self.NUM_RESULTS}"

settings = Settings()

