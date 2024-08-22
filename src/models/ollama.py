import requests
from flask import current_app

class OllamaModel:
    def __init__(self):
        self.base_url = current_app.config['OLLAMA_API_BASE_URL']

    def list_models(self):
        response = requests.get(f"{self.base_url}/api/tags")
        response.raise_for_status()
        return response.json()

    def generate(self, data):
        response = requests.post(f"{self.base_url}/api/generate", json=data)
        response.raise_for_status()
        return response.json()
