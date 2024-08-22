from flask import Blueprint, jsonify, request
from src.models.ollama import OllamaModel
from src.utils.decorators import api_key_required

api_bp = Blueprint('api', __name__)

ollama_model = OllamaModel()

@api_bp.route('/models', methods=['GET'])
@api_key_required
def list_models():
    models = ollama_model.list_models()
    return jsonify(models)

@api_bp.route('/generate', methods=['POST'])
@api_key_required
def generate():
    data = request.json
    response = ollama_model.generate(data)
    return jsonify(response)
