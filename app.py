from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

app = Flask(__name__)
limiter = Limiter(app, key_func=get_remote_address)

@app.route('/generate', methods=['POST'])
@limiter.limit("5 per minute")
def generate():
    # ... existing code ...