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
    cmd = [
        "sips",
        "-z",
        str(dimension),
        str(dimension),
        source_image,
        "--out",
        output_path,
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)

    return {"idiom": "mac", "scale": scale_str, "filename": filename}


# 18pt is a good standard for menu bar icons
ICON_SIZE = 18

print(f"Generating menu bar icons (base size {ICON_SIZE}pt)...")
images_config.append(generate_icon(ICON_SIZE, 1))
images_config.append(generate_icon(ICON_SIZE, 2))
# Add 3x just in case future proofing/other displays, though 1x/2x is standard for mac
images_config.append(generate_icon(ICON_SIZE, 3))

contents_json = {"images": images_config, "info": {"version": 1, "author": "xcode"}}

with open(os.path.join(output_dir, "Contents.json"), "w") as f:
    json.dump(contents_json, f, indent=2)

print("Done! MenuBarIcon.imageset updated.")

# Also generate a larger icon for the About view
about_output_dir = "../macory/Assets.xcassets/AboutIcon.imageset"
if not os.path.exists(about_output_dir):
    os.makedirs(about_output_dir)

about_images_config = []
# Generate 128x128 for About view (covers plenty of size)
ABOUT_SIZE = 128
dimension = ABOUT_SIZE
filename = f"about_icon_{ABOUT_SIZE}.png"
output_path = os.path.join(about_output_dir, filename)

cmd = ["sips", "-z", str(dimension), str(dimension), source_image, "--out", output_path]
subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)

about_images_config.append({"idiom": "universal", "scale": "1x", "filename": filename})

# 2x
dimension = ABOUT_SIZE * 2
filename_2x = f"about_icon_{ABOUT_SIZE}@2x.png"
output_path_2x = os.path.join(about_output_dir, filename_2x)
cmd = [
    "sips",
    "-z",
    str(dimension),
    str(dimension),
    source_image,
    "--out",
    output_path_2x,
]
subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)

about_images_config.append(
    {"idiom": "universal", "scale": "2x", "filename": filename_2x}
)

about_contents = {
    "images": about_images_config,
    "info": {"version": 1, "author": "xcode"},
}

with open(os.path.join(about_output_dir, "Contents.json"), "w") as f:
    json.dump(about_contents, f, indent=2)

print("Done! AboutIcon.imageset generated.")
