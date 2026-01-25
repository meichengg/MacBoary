import os
import subprocess
import json

source_image = "../macory/trayicon.png"
output_dir = "../macory/Assets.xcassets/MenuBarIcon.imageset"

# Ensure absolute paths
script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

if not os.path.exists(source_image):
    print(f"Error: Source image not found at {source_image}")
    exit(1)

images_config = []

def generate_icon(size_pt, scale):
    dimension = int(size_pt * scale)
    scale_str = f"{scale}x"
    filename = f"menubar_{size_pt}pt_{scale_str}.png"
    if scale == 1:
        filename = f"menubar_{size_pt}pt.png"
    else:
        filename = f"menubar_{size_pt}pt@{scale_str}.png"
        
    output_path = os.path.join(output_dir, filename)
    
    # Run sips to resize
    cmd = ["sips", "-z", str(dimension), str(dimension), source_image, "--out", output_path]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)
    
    return {
        "idiom": "mac",
        "scale": scale_str,
        "filename": filename
    }

# 18pt is a good standard for menu bar icons
ICON_SIZE = 18

print(f"Generating menu bar icons (base size {ICON_SIZE}pt)...")
images_config.append(generate_icon(ICON_SIZE, 1))
images_config.append(generate_icon(ICON_SIZE, 2))
# Add 3x just in case future proofing/other displays, though 1x/2x is standard for mac
images_config.append(generate_icon(ICON_SIZE, 3))

contents_json = {
    "images": images_config,
    "info": {
        "version": 1,
        "author": "xcode"
    }
}

with open(os.path.join(output_dir, "Contents.json"), "w") as f:
    json.dump(contents_json, f, indent=2)

print("Done! MenuBarIcon.imageset updated.")
