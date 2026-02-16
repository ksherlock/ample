from PIL import Image
import os
import sys

def create_linux_icons(source_png, output_dir):
    """Generate multiple PNG icon sizes for Linux desktop integration."""
    print(f"Opening source: {source_png}")
    try:
        img = Image.open(source_png)
    except Exception as e:
        print(f"Error opening image: {e}")
        return False

    # Standard Linux icon sizes (freedesktop.org spec)
    icon_sizes = [512, 256, 128, 64, 48, 32, 16]

    os.makedirs(output_dir, exist_ok=True)

    for size in icon_sizes:
        resized = img.resize((size, size), Image.LANCZOS)
        out_path = os.path.join(output_dir, f"ample_{size}x{size}.png")
        resized.save(out_path, format='PNG')
        print(f"  Saved: {out_path}")

    # Also save a default icon at top level
    default_icon = os.path.join(os.path.dirname(output_dir), "ample.png")
    img.resize((256, 256), Image.LANCZOS).save(default_icon, format='PNG')
    print(f"  Saved default icon: {default_icon}")

    print("Success!")
    return True

if __name__ == "__main__":
    src = os.path.join("..", "Ample", "Assets.xcassets", "AppIcon.appiconset", "icon-1024.png")
    dst_dir = "icons"

    # Check if source exists
    if not os.path.exists(src):
        print(f"Source file not found: {src}")
        print("Make sure you run this script from the AmpleLinux directory.")
        sys.exit(1)

    if create_linux_icons(src, dst_dir):
        sys.exit(0)
    else:
        sys.exit(1)
