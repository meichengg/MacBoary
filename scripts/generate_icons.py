import os
import subprocess
import json

source_image = "../macory/appicon.png"
output_dir = "../macory/Assets.xcassets/AppIcon.appiconset"

# Ensure absolute paths
script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

if not os.path.exists(source_image):
    print(f"Error: Source image not found at {source_image}")
    exit(1)

images_config = []

def generate_icon(size, scale):
    dimension = size * scale
    scale_str = f"{scale}x"
    filename = f"icon_{size}x{size}_{scale_str}.png"
    if scale == 1:
        filename = f"icon_{size}x{size}.png"
    else:
        filename = f"icon_{size}x{size}@{scale_str}.png"
        
    output_path = os.path.join(output_dir, filename)
    
    # Run sips to resize
    cmd = ["sips", "-z", str(dimension), str(dimension), source_image, "--out", output_path]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)
    
    return {
        "size": f"{size}x{size}",
        "idiom": "mac",
        "filename": filename,
        "scale": scale_str
    }

sizes = [16, 32, 128, 256, 512]

print("Generating icons...")
for size in sizes:
    # 1x
    images_config.append(generate_icon(size, 1))
    # 2x
    images_config.append(generate_icon(size, 2))

contents_json = {
    "images": images_config,
    "info": {
        "version": 1,
        "author": "xcode"
    }
}

with open(os.path.join(output_dir, "Contents.json"), "w") as f:
    json.dump(contents_json, f, indent=2)

print("Done! Contents.json updated.")
