import os
import json
import logging
from typing import Optional, Literal
from pydantic import Field, computed_field
from pydantic_settings import BaseSettings
import boto3
from functools import lru_cache

logger = logging.getLogger(__name__)
LogLevel = Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]

class Settings(BaseSettings):
    # API keys (will be populated from .env or AWS SSM Parameter Store)
    PLANTNET_API_KEY: Optional[str] = None
    ANTHROPIC_API_KEY: Optional[str] = None

    # Logging configuration
    LOG_LEVEL: LogLevel = Field(default="INFO")
    LOG_FORMAT: str = "%(asctime)s - %(levelname)s - %(message)s"

    # Application settings with defaults
    UPLOAD_DIR: str = "uploads"
    RHS_BASE_URL: str = "https://www.rhs.org.uk/plants/search-results?query="

    # PlantNet API settings with defaults
    PROJECT: str = "all"
    NUM_RESULTS: int = 3
    SIMSEARCH: bool = True

    # Define PLANTNET_ENDPOINT dynamically so it updates if other settings change
    @computed_field
    def PLANTNET_ENDPOINT(self) -> str:
        return f"https://my-api.plantnet.org/v2/identify/{self.PROJECT}?api-key={self.PLANTNET_API_KEY}&nb-results={self.NUM_RESULTS}&include-related-images={self.SIMSEARCH}"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

    def __init__(self, **kwargs):
        # First initiliase with environment variables
        super().__init__(**kwargs)

        # Then check AWS SSM Parameter Store if running in AWS
        if self._is_running_in_aws():
            self._load_ssm_parameters(names=["PLANTNET_API_KEY", "ANTHROPIC_API_KEY"])

    def _is_running_in_aws(self) -> bool:
        """Check if the application is running in an AWS environment."""
        return os.getenv("AWS_EXECUTION_ENV") is not None

    def _load_ssm_parameters(self, names: list, region_name: str = "eu-west-2", with_decryption: bool = True) -> dict:
        """Load secrets from AWS SSM Parameter Store into settings."""
        try:
            ssm_client = boto3.client("ssm", region_name=region_name)
            response = ssm_client.get_parameters(Names=names, WithDecryption=with_decryption)
            secrets = {param["Name"]: param["Value"] for param in response["Parameters"]}
            
            # Update any None values with secrets
            for key, value in secrets.items():
                if hasattr(self, key) and getattr(self, key) is None:
                    setattr(self, key, value)
        except Exception as e:
            logger.error(f"Error retrieving AWS SSM Parameters: {e}")
    
    def setup_logging(self):
        """Configure logging based on settings."""
        logging.basicConfig(
            level=getattr(logging, self.LOG_LEVEL),
            format=self.LOG_FORMAT
        )
        return logging.getLogger()

@lru_cache
def get_settings() -> Settings:
    """Creates and returns a cached Settings instance."""
    # For dependency injection
    return Settings()

# For simple imports
settings = Settings()

