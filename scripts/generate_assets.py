import os
import subprocess
import json

# Paths
SOURCE_IMAGE = "../assets/trayicon.png"
ASSETS_DIR = "../macboary/Assets.xcassets"

# Ensure absolute paths
script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

if not os.path.exists(SOURCE_IMAGE):
    print(f"Error: Source image not found at {SOURCE_IMAGE}")
    exit(1)

if not os.path.exists(ASSETS_DIR):
    os.makedirs(ASSETS_DIR)


def resize_image(output_path, width, height, source=SOURCE_IMAGE):
    cmd = ["sips", "-z", str(height), str(width), source, "--out", output_path]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)


def generate_contents_json(images_config, output_dir):
    contents_json = {"images": images_config, "info": {"version": 1, "author": "xcode"}}
    with open(os.path.join(output_dir, "Contents.json"), "w") as f:
        json.dump(contents_json, f, indent=2)


# 1. Generate AppIcon (Dock)
def generate_app_icons():

    def resize_and_pad(
        output_path, target_dimension, content_dimension, source=SOURCE_IMAGE
    ):
        temp_path = output_path + ".temp.png"
        resize_image(temp_path, content_dimension, content_dimension, source)

        # Pad to target dimension
        # Note: sips padColor defaults to black/white depending on version,
        # but for app icons typically squircle shape is handled by system unless pre-composed.
        # User requested 832 size on 1024 canvas.
        cmd = [
            "sips",
            "--padToHeightWidth",
            str(target_dimension),
            str(target_dimension),
            temp_path,
            "--out",
            output_path,
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)

        if os.path.exists(temp_path):
            os.remove(temp_path)

    print("Generating AppIcons...")
    output_dir = os.path.join(ASSETS_DIR, "AppIcon.appiconset")
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    images_config = []
    sizes = [16, 32, 128, 256, 512]

    # 832/1024 = 0.8125
    CONTENT_RATIO = 832.0 / 1024.0

    for size in sizes:
        for scale in [1, 2]:
            dimension = size * scale
            scale_str = f"{scale}x"
            filename = f"icon_{size}x{size}_{scale_str}.png"
            if scale == 1:
                filename = f"icon_{size}x{size}.png"
            else:
                filename = f"icon_{size}x{size}@{scale_str}.png"

            content_dimension = int(dimension * CONTENT_RATIO)
            resize_and_pad(
                os.path.join(output_dir, filename), dimension, content_dimension
            )

            images_config.append(
                {
                    "size": f"{size}x{size}",
                    "idiom": "mac",
                    "filename": filename,
                    "scale": scale_str,
                }
            )

    generate_contents_json(images_config, output_dir)


# 2. Generate MenuBarIcon (Tray)
def generate_menubar_icons():
    print("Generating MenuBarIcons...")
    output_dir = os.path.join(ASSETS_DIR, "MenuBarIcon.imageset")
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    images_config = []
    ICON_SIZE = 18  # pt

    for scale in [1, 2, 3]:
        dimension = ICON_SIZE * scale
        scale_str = f"{scale}x"
        filename = f"menubar_{ICON_SIZE}pt_{scale_str}.png"
        if scale == 1:
            filename = f"menubar_{ICON_SIZE}pt.png"
        else:
            filename = f"menubar_{ICON_SIZE}pt@{scale_str}.png"

        resize_image(os.path.join(output_dir, filename), dimension, dimension)

        images_config.append({"idiom": "mac", "scale": scale_str, "filename": filename})

    generate_contents_json(images_config, output_dir)


# 3. Generate AboutIcon (About View)
def generate_about_icon():
    print("Generating AboutIcon...")
    output_dir = os.path.join(ASSETS_DIR, "AboutIcon.imageset")
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    images_config = []
    SIZE = 128  # pt

    for scale in [1, 2]:
        dimension = SIZE * scale
        scale_str = f"{scale}x"
        filename = f"about_icon_{SIZE}_{scale_str}.png"
        if scale == 1:
            filename = f"about_icon_{SIZE}.png"
        else:
            filename = f"about_icon_{SIZE}@{scale_str}.png"

        resize_image(os.path.join(output_dir, filename), dimension, dimension)

        images_config.append(
            {"idiom": "universal", "scale": scale_str, "filename": filename}
        )

    generate_contents_json(images_config, output_dir)


# 4. Generate EmptyListIcon (For empty state)
def generate_empty_list_icon():
    print("Generating EmptyListIcon...")
    output_dir = os.path.join(ASSETS_DIR, "EmptyListIcon.imageset")
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    images_config = []
    SIZE = 64  # pt

    for scale in [1, 2, 3]:
        dimension = SIZE * scale
        scale_str = f"{scale}x"
        filename = f"emptylist_icon_{SIZE}_{scale_str}.png"
        if scale == 1:
            filename = f"emptylist_icon_{SIZE}.png"
        else:
            filename = f"emptylist_icon_{SIZE}@{scale_str}.png"

        resize_image(os.path.join(output_dir, filename), dimension, dimension)

        images_config.append(
            {"idiom": "universal", "scale": scale_str, "filename": filename}
        )

    generate_contents_json(images_config, output_dir)


def main():
    generate_app_icons()
    generate_menubar_icons()
    generate_about_icon()
    generate_empty_list_icon()
    print("All icons generated successfully!")


if __name__ == "__main__":
    main()
