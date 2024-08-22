#!/bin/bash

# Create project structure
mkdir -p ollama_project/{src,templates,static}
cd ollama_project

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install flask requests python-dotenv Flask-Limiter bleach

# Create ollama_integration.py
cat > src/ollama_integration.py << EOL
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
EOL

# Create app.py
cat > app.py << EOL
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
EOL

# Create index.html
cat > templates/index.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ollama Model Interface</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='styles.css') }}">
</head>
<body>
    <div class="container">
        <h1>Ollama Model Interface</h1>
        <form id="generateForm">
            <div class="form-group">
                <label for="model">Select Model:</label>
                <select name="model" id="model">
                    {% for model in models %}
                        <option value="{{ model.name }}">{{ model.name }}</option>
                    {% endfor %}
                </select>
            </div>
            <div class="form-group">
                <label for="prompt">Enter Prompt:</label>
                <textarea name="prompt" id="prompt" rows="4"></textarea>
            </div>
            <button type="submit">Generate</button>
        </form>
        <div id="error-message" class="error-message"></div>
        <div id="loading" class="loading">Generating response...</div>
        <div id="output"></div>
    </div>

    <script>
    document.getElementById('generateForm').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const promptInput = document.getElementById('prompt');
        const modelSelect = document.getElementById('model');
        
        if (promptInput.value.trim() === '') {
            showError('Please enter a prompt.');
            return;
        }
        
        if (modelSelect.value === '') {
            showError('Please select a model.');
            return;
        }
        
        submitForm(this);
    });

    function showError(message) {
        const errorDiv = document.getElementById('error-message');
        errorDiv.textContent = message;
        errorDiv.style.display = 'block';
        setTimeout(() => {
            errorDiv.style.display = 'none';
        }, 3000);
    }

    function submitForm(form) {
        const loadingIndicator = document.getElementById('loading');
        const outputDiv = document.getElementById('output');
        const submitButton = form.querySelector('button[type="submit"]');
        
        loadingIndicator.style.display = 'block';
        outputDiv.innerText = '';
        submitButton.disabled = true;
        
        fetch('/generate', {
            method: 'POST',
            body: new FormData(form)
        })
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            loadingIndicator.style.display = 'none';
            submitButton.disabled = false;
            
            if (data.output) {
                outputDiv.innerText = data.output;
            } else if (data.error) {
                showError(data.error);
            }
        })
        .catch(error => {
            loadingIndicator.style.display = 'none';
            submitButton.disabled = false;
            showError(`An error occurred: ${error.message}`);
        });
    }
    </script>
</body>
</html>
EOL

# Create styles.css
cat > static/styles.css << EOL
@import url('https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;700&display=swap');

body {
    font-family: 'Roboto', sans-serif;
    line-height: 1.6;
    margin: 0;
    padding: 20px;
    background-color: #f4f4f4;
}

.container {
    max-width: 800px;
    margin: 0 auto;
    background-color: #fff;
    padding: 20px;
    border-radius: 5px;
    box-shadow: 0 0 10px rgba(0,0,0,0.1);
}

h1 {
    color: #333;
    text-align: center;
}

.form-group {
    margin-bottom: 15px;
}

label {
    display: block;
    margin-bottom: 5px;
}

select, textarea {
    width: 100%;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 16px;
}

button {
    background-color: #4CAF50;
    color: white;
    padding: 10px 15px;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 16px;
    transition: background-color 0.3s ease;
}

button:hover {
    background-color: #45a049;
}

button:disabled {
    background-color: #cccccc;
    cursor: not-allowed;
}

#output {
    margin-top: 20px;
    padding: 15px;
    background-color: #f9f9f9;
    border-radius: 5px;
    border: 1px solid #ddd;
}

.loading {
    display: none;
    text-align: center;
    margin-top: 20px;
    font-style: italic;
    color: #666;
}

.loading::after {
    content: '';
    animation: dots 1.5s steps(5, end) infinite;
}

@keyframes dots {
    0%, 20% {
        content: '';
    }
    40% {
        content: '.';
    }
    60% {
        content: '..';
    }
    80%, 100% {
        content: '...';
    }
}

.error-message {
    display: none;
    color: #d32f2f;
    background-color: #fde8e8;
    border: 1px solid #d32f2f;
    padding: 10px;
    margin-top: 10px;
    border-radius: 4px;
}

@media (max-width: 600px) {
    .container {
        width: 100%;
        padding: 10px;
    }
}
EOL

# Create .env file
echo "HUGGINGFACE_TOKEN=your_token_here" > .env

echo "Setup complete. Run 'flask run' to start the application."
