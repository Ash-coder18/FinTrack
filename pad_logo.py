from PIL import Image

def pad_logo():
    try:
        img = Image.open('assets/icon/logo.png').convert('RGBA')
        old_w, old_h = img.size
        # Shrink to 65% to add safe zone padding
        new_w, new_h = int(old_w * 0.65), int(old_h * 0.65)
        resized_img = img.resize((new_w, new_h), Image.LANCZOS)
        
        # New canvas with transparent background
        new_img = Image.new('RGBA', (old_w, old_h), (0, 0, 0, 0))
        paste_x = (old_w - new_w) // 2
        paste_y = (old_h - new_h) // 2
        new_img.paste(resized_img, (paste_x, paste_y), resized_img)
        
        new_img.save('assets/icon/logo_padded.png')
        print("Padded logo created successfully.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    pad_logo()
