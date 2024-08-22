document.getElementById('promptForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const prompt = document.getElementById('prompt').value;
    const responseDiv = document.getElementById('response');
    
    responseDiv.innerHTML = 'Generating...';
    
    try {
        const response = await fetch('/generate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ prompt }),
        });
        
        const data = await response.json();
        
        if (response.ok) {
            responseDiv.innerHTML = ;
        } else {
            responseDiv.innerHTML = ;
        }
    } catch (error) {
        responseDiv.innerHTML = ;
    }
});
