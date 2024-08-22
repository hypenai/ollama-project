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
