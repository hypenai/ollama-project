import os
import requests
from dotenv import load_dotenv

load_dotenv()

def get_ollama_models():
    url = "https://ollama.ai/api/models"
    headers = {"Authorization": f"Bearer {os.getenv('HUGGINGFACE_TOKEN')}"}
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        return response.json()
    else:
        return None

def run_ollama_model(model_name, prompt):
    try:
        url = f"https://ollama.ai/api/run/{model_name}"
        headers = {"Authorization": f"Bearer {os.getenv('HUGGINGFACE_TOKEN')}"}
        data = {"prompt": prompt}
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"An error occurred: {e}")
        return None

def run_ollama_model_with_fallback(model, prompt):
    try:
        return run_ollama_model(model, prompt)
    except requests.RequestException:
        print("Ollama service unavailable. Using fallback.")
        return {"output": "Sorry, the model is currently unavailable. Please try again later."}
