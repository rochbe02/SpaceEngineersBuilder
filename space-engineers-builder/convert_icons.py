import os
from PIL import Image

SE_PATH = r"B:\SteamLibrary\steamapps\common\SpaceEngineers\Content"
ICONS_PATH = os.path.join(SE_PATH, "Textures", "GUI", "Icons", "Cubes")
OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "assets", "blocks", "icons")

os.makedirs(OUTPUT_PATH, exist_ok=True)

converted = 0
errors = 0

for filename in os.listdir(ICONS_PATH):
    if filename.lower().endswith(".dds"):
        input_path = os.path.join(ICONS_PATH, filename)
        output_name = os.path.splitext(filename)[0] + ".png"
        output_path = os.path.join(OUTPUT_PATH, output_name)
        
        try:
            img = Image.open(input_path)
            img.save(output_path)
            converted += 1
        except Exception as e:
            print(f"Error con {filename}: {e}")
            errors += 1

print(f"Convertidos: {converted}, Errores: {errors}")
print(f"Guardados en: {OUTPUT_PATH}")