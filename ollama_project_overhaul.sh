#!/bin/bash

# ollama_project_overhaul.sh
# CodeTitanX's Magnum Opus for Ollama Project Transformation

set -euo pipefail

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check and install dependencies
install_dependencies() {
    log "Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip docker.io docker-compose git curl
    pip3 install --upgrade pip
    pip3 install pytest flake8 black mypy
}

# Function to set up the project structure
setup_project_structure() {
    log "Setting up project structure..."
    mkdir -p src tests docs
    touch src/__init__.py tests/__init__.py
    echo "# Ollama Project" > README.md
}

# Function to create main application file
create_main_app() {
    log "Creating main application file..."
    cat << EOF > src/main.py
import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx

app = FastAPI()

class Query(BaseModel):
    prompt: str

OLLAMA_API_URL = os.getenv('OLLAMA_API_URL', 'http://localhost:11434')

@app.post("/generate")
async def generate(query: Query):
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{OLLAMA_API_URL}/api/generate",
                json={"model": "llama2", "prompt": query.prompt}
            )
            response.raise_for_status()
            return response.json()
    except httpx.HTTPError as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF
}

# Function to create Docker-related files
create_docker_files() {
    log "Creating Docker-related files..."
    cat << EOF > Dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .

CMD ["python", "main.py"]
EOF

    cat << EOF > docker-compose.yml
version: '3'
services:
  ollama:
    image: ollama/ollama
    ports:
      - "11434:11434"
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - OLLAMA_API_URL=http://ollama:11434
    depends_on:
      - ollama
EOF
}

# Function to create test files
create_test_files() {
    log "Creating test files..."
    cat << EOF > tests/test_main.py
from fastapi.testclient import TestClient
from src.main import app

client = TestClient(app)

def test_generate():
    response = client.post("/generate", json={"prompt": "Hello, world!"})
    assert response.status_code == 200
    assert "response" in response.json()
EOF
}

# Function to create CI/CD pipeline
create_cicd_pipeline() {
    log "Creating CI/CD pipeline..."
    mkdir -p .github/workflows
    cat << EOF > .github/workflows/ci_cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.10'
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    - name: Run tests
      run: pytest
    - name: Run linters
      run: |
        flake8 .
        black --check .
        mypy src

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v2
    - name: Build and push Docker image
      env:
        DOCKER_USERNAME: \${{ secrets.DOCKER_USERNAME }}
        DOCKER_PASSWORD: \${{ secrets.DOCKER_PASSWORD }}
      run: |
        docker build -t hypenai/ollama-project:latest .
        echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USERNAME --password-stdin
        docker push hypenai/ollama-project:latest
EOF
}

# Function to create requirements file
create_requirements() {
    log "Creating requirements file..."
    cat << EOF > requirements.txt
fastapi
uvicorn
httpx
pytest
flake8
black
mypy
EOF
}

# Function to initialize git repository
init_git_repo() {
    log "Initializing git repository..."
    git init
    echo ".env" > .gitignore
    git add .
    git commit -m "Initial commit"
}

# Function to install GitHub CLI
install_github_cli() {
    log "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
}

# Function to set up GitHub repository
setup_github_repo() {
    log "Setting up GitHub repository..."
    if ! command -v gh &> /dev/null; then
        log "GitHub CLI not found. Installing..."
        install_github_cli
    fi
    gh auth login --with-token <<< "$GITHUB_TOKEN"
    gh repo create ollama-project --public --source=. --remote=origin
    git push -u origin main
}

# Function to set up Docker Hub
setup_docker_hub() {
    log "Setting up Docker Hub..."
    echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
}

# Main execution
main() {
    log "Starting Ollama project overhaul..."
    
    install_dependencies
    setup_project_structure
    create_main_app
    create_docker_files
    create_test_files
    create_cicd_pipeline
    create_requirements
    init_git_repo
    
    # Set up GitHub repository
    read -p "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
    setup_github_repo
    
    # Set up Docker Hub
    read -p "Enter your Docker Hub username: " DOCKER_USERNAME
    read -s -p "Enter your Docker Hub password: " DOCKER_PASSWORD
    echo
    setup_docker_hub
    
    log "Ollama project overhaul complete!"
}

main
