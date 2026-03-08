from PIL import Image
import os
import sys

def create_ico(source_png, output_ico):
    print(f"Opening source: {source_png}")
    try:
        img = Image.open(source_png)
    except Exception as e:
        print(f"Error opening image: {e}")
        return False
        
    # Windows icon sizes
    icon_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
    
    print(f"Saving icon to: {output_ico}")
    try:
        img.save(output_ico, format='ICO', sizes=icon_sizes)
        print("Success!")
        return True
    except Exception as e:
        print(f"Error saving ICO: {e}")
        return False

if __name__ == "__main__":
    src = r"..\Ample\Assets.xcassets\AppIcon.appiconset\icon-1024.png"
    dst = "app_icon.ico"
    
    # Check if source exists
    if not os.path.exists(src):
        print(f"Source file not found: {src}")
        sys.exit(1)
        
    if create_ico(src, dst):
        sys.exit(0)
    else:
        sys.exit(1)
