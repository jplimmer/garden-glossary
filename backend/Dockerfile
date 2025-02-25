# Use Miniconda as the base image
FROM continuumio/miniconda3

# Set working directory inside the container
WORKDIR /app

# Copy conda environment and install dependencies
COPY environment.yml /app/environment.yml
RUN conda env create -f /app/environment.yml

# Activate conda environment for all future RUN, CMD, and ENTRYPOINT commands
SHELL ["conda", "run", "-n", "garden_glossary", "/bin/bash", "-c"]

# Copy backend code into the container
COPY . /app

# Add 'src' to the Python path
ENV PYTHONPATH="${PYTHONPATH}:/app/src"

# Set the environment variable to indicate we're running in a container
ENV DOCKER_ENVIRONMENT=1

# Expose FastAPI port
EXPOSE 8000

# Run FastAPI with Uvicorn
CMD [ "conda", "run", "--no-capture-output", "-n", "garden_glossary", "uvicorn", "src.app.main:app", "--host", "0.0.0.0", "--port", "8000" ]

