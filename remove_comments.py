import os
import re

pattern = re.compile(
    r'(r?"""[\s\S]*?""")|'      
    r"(r?'''[\s\S]*?''')|"      
    r'(r?"(?:[^"\\]|\\.)*")|'   
    r"(r?'(?:[^'\\]|\\.)*')|"   
    r'(//.*)|'                  
    r'(/\*[\s\S]*?\*/)'         
)

def replacer(match):
    if match.group(1) is not None: return match.group(1)
    if match.group(2) is not None: return match.group(2)
    if match.group(3) is not None: return match.group(3)
    if match.group(4) is not None: return match.group(4)
    # It's a comment
    return ""

def process_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return

    new_content = pattern.sub(replacer, content)

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Removed comments in {filepath}")

if __name__ == "__main__":
    dirs = ['lib', 'test']
    for d in dirs:
        if not os.path.exists(d):
            continue
        for root, _, files in os.walk(d):
            for file in files:
                if file.endswith('.dart'):
                    process_file(os.path.join(root, file))
