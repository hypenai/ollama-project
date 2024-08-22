import pytest
from src.app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index_route(client):
    response = client.get('/')
    assert response.status_code == 200

def test_generate_route(client):
    response = client.post('/generate', json={'prompt': 'Test prompt'})
    assert response.status_code == 200
    assert 'response' in response.json

def test_invalid_prompt(client):
    response = client.post('/generate', json={'prompt': '<script>alert("XSS")</script>'})
    assert response.status_code == 400
    assert 'error' in response.json
