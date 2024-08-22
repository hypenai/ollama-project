from flask import Flask, request, jsonify, render_template
from src.ollama_integration import get_ollama_models, run_ollama_model_with_fallback
import bleach
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import logging
from logging.handlers import RotatingFileHandler

app = Flask(__name__, static_folder='static')
limiter = Limiter(app, key_func=get_remote_address)

@app.errorhandler(Exception)
def handle_exception(e):
    app.logger.error(f"An error occurred: {str(e)}")
    return jsonify(error="An unexpected error occurred. Please try again later."), 500

@app.route('/')
def index():
    models = get_ollama_models()
    return render_template('index.html', models=models)

@app.route('/generate', methods=['POST'])
@limiter.limit("5 per minute")
def generate():
    try:
        model = bleach.clean(request.form['model'])
        prompt = bleach.clean(request.form['prompt'])
        
        if not prompt.strip():
            return jsonify(error="Prompt cannot be empty."), 400
        
        result = run_ollama_model_with_fallback(model, prompt)
        if result:
            return jsonify({'output': result['output']})
        else:
            return jsonify(error="Failed to generate response. Please try again."), 500
    except KeyError:
        return jsonify(error="Invalid request. Please provide both model and prompt."), 400

if __name__ == '__main__':
    handler = RotatingFileHandler('app.log', maxBytes=10000, backupCount=1)
    handler.setLevel(logging.INFO)
    app.logger.addHandler(handler)
    app.run(debug=True)
