from PIL import Image

def create_gif_from_spritesheet(sheet_path, output_path, cols=4):
    try:
        sheet = Image.open(sheet_path).convert("RGBA")
        
        # Dimensions of the entire sheet
        sheet_w, sheet_h = sheet.size
        frame_w = sheet_w // cols
        frame_h = sheet_h
        
        frames = []
        for i in range(cols):
            # Crop each frame
            left = i * frame_w
            right = (i + 1) * frame_w
            frame = sheet.crop((left, 0, right, frame_h))
            
            # Create a new image with white background to prevent alpha issues in some basic GIF viewers
            # But wait, Flutter supports transparent GIFs! So let's keep it transparent.
            frames.append(frame)
            
        # Save as GIF
        frames[0].save(
            output_path,
            save_all=True,
            append_images=frames[1:],
            duration=150, # milliseconds per frame (roughly 6-7 fps)
            loop=0, # loop infinitely
            disposal=2 # clear frame before rendering next (important for transparency)
        )
        print("Successfully created GIF!")
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    create_gif_from_spritesheet(r"assets\images\pilgrim_animated.png", r"assets\images\pilgrim.gif")
