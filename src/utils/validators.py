import re

def validate_prompt(prompt):
    if not prompt or len(prompt) > 1000:
        return False
    if re.search(r'[<>{}]', prompt):
        return False
    return True
