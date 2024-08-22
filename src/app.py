from flask import Flask, request, jsonify, render_template
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import requests
import bleach
from dotenv import load_dotenv
import os

from src.api.routes import api_bp
from src.utils.validators import validate_prompt
from src.config.settings import AppConfig

load_dotenv()

app = Flask(__name__)
app.config.from_object(AppConfig)

limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=[os.getenv("RATE_LIMIT", "100 per minute")],
    storage_uri="memory://",
)

app.register_blueprint(api_bp, url_prefix='/api')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/generate', methods=['POST'])
@limiter.limit("10 per minute")
def generate():
    data = request.json
    prompt = data.get('prompt', '')
    
    if not validate_prompt(prompt):
        return jsonify({"error": "Invalid prompt"}), 400
    
    sanitized_prompt = bleach.clean(prompt)
    
    try:
        response = requests.post(
            f"{app.config['OLLAMA_API_BASE_URL']}/api/generate",
            json={"model": "llama2", "prompt": sanitized_prompt}
        )
        response.raise_for_status()
        return jsonify(response.json())
    except requests.RequestException as e:
        app.logger.error(f"Ollama API error: {str(e)}")
        return jsonify({"error": "Failed to generate response"}), 500

if __name__ == '__main__':
    app.run(debug=app.config['DEBUG'], host='0.0.0.0')
