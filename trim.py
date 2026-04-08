import re

with open("lib/screens/dashboard.dart", "r", encoding="utf-8") as f:
    text = f.read()

# find the exact string to cut off at
match = "      );\n  }\n}"
idx = text.find(match)
if idx != -1:
    text = text[:idx + len(match)] + "\n"
    with open("lib/screens/dashboard.dart", "w", encoding="utf-8") as f:
        f.write(text)
    print("Trimmed successfully.")
else:
    print("Match not found.")
