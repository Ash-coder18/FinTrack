import json
import urllib.request
import ssl

def to_hex(c):
    return f"{int(c * 255):02X}"

def figma_to_flutter_color(r, g, b, a=1.0):
    return f"0x{to_hex(a)}{to_hex(r)}{to_hex(g)}{to_hex(b)}"

colors = set()
bg_colors = set()
typography = {}

def traverse(node):
    if not isinstance(node, dict):
        return

    if "backgroundColor" in node:
        c = node["backgroundColor"]
        bg_colors.add(figma_to_flutter_color(c.get('r', 0), c.get('g', 0), c.get('b', 0), c.get('a', 1)))

    ills = node.get("fills", [])
    if isinstance(ills, list):
        for fill in ills:
            if isinstance(fill, dict) and fill.get("type") == "SOLID" and "color" in fill:
                c = fill["color"]
                opacity = fill.get("opacity", 1.0)
                colors.add(figma_to_flutter_color(c.get('r', 0), c.get('g', 0), c.get('b', 0), c.get('a', 1) * opacity))

    if node.get("type") == "TEXT":
        style = node.get("style", {})
        if "fontFamily" in style:
            font_family = style.get("fontFamily")
            font_weight = style.get("fontWeight", 400)
            font_size = style.get("fontSize", 14)
            key = f"{font_family}_{font_weight}_{int(font_size)}"
            if key not in typography:
                typography[key] = {
                    "fontFamily": font_family,
                    "fontWeight": font_weight,
                    "fontSize": font_size
                }

    children = node.get("children", [])
    if isinstance(children, list):
        for child in children:
            if isinstance(child, dict):
                traverse(child)

if __name__ == "__main__":
    url = "https://api.figma.com/v1/files/spRk89SWi4Cpv9wgjgZRMp"
    req = urllib.request.Request(url, headers={"X-Figma-Token": "YOUR_TOKEN_GOES_HERE"})
    
    # Ignore SSL errors just in case
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    print("Fetching Figma data...")
    try:
        with urllib.request.urlopen(req, context=ctx) as response:
            data = json.loads(response.read().decode("utf-8"))
            
            if "document" in data:
                traverse(data["document"])
                print("--- COLORS (Fills) ---")
                for c in sorted(colors):
                    print(c)
                print("\n--- BACKGROUND COLORS ---")
                for c in sorted(bg_colors):
                    print(c)
                print("\n--- TYPOGRAPHY ---")
                for key, val in typography.items():
                    print(f"{key}: {val}")
            else:
                print("No 'document' key in JSON. Keys:", list(data.keys()))
                if "error" in data:
                    print("Error:", data["error"])
    except Exception as e:
        print("Error fetching data:", e)
