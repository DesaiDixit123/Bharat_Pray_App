import math
from PIL import Image, ImageDraw

def generate_yatra_gif():
    try:
        width = 400
        height = 800
        frames = []
        num_frames = 24
        
        # Load the transparent character
        char_img = Image.open(r"assets\images\pilgrim_character_transparent.png").convert("RGBA")
        # Resize character to appropriate width (e.g., 140px)
        ratio = char_img.height / char_img.width
        char_w = 140
        char_h = int(140 * ratio)
        char_img = char_img.resize((char_w, char_h), Image.Resampling.LANCZOS)
        
        # We need to clip the bottom of the character (hide static feet)
        char_img = char_img.crop((0, 0, char_w, char_h - 25))
        
        for i in range(num_frames):
            # Create base frame
            frame = Image.new("RGBA", (width, height), (76, 175, 80, 255)) # Green Grass #4CAF50
            draw = ImageDraw.Draw(frame)
            
            # Draw Grey Road
            road_width = 240
            road_left = (width - road_width) // 2
            draw.rectangle([road_left, 0, road_left + road_width, height], fill=(107, 107, 107, 255)) # Grey #6B6B6B
            
            # Draw scrolling dashed lines
            # Line length 50, gap 50. Loop length is 100.
            progress = i / num_frames
            y_offset = int(progress * 100)
            
            for y in range(-100 + y_offset, height, 100):
                draw.line([(width//2, y), (width//2, y + 50)], fill=(255, 255, 255, 255), width=6)
                
            # Draw Player
            cx = width // 2
            cy = height - 200 # Fixed position near bottom
            
            # Animation cycle 0 to 2*PI
            walk_cycle = progress * 2 * math.pi
            
            # 1. Drop shadow
            shadow_scale = 1.0 - (abs(math.sin(walk_cycle)) * 0.15)
            sw = int(60 * shadow_scale)
            sh = int(18 * shadow_scale)
            draw.ellipse([cx - sw//2, cy - sh//2, cx + sw//2, cy + sh//2], fill=(0, 0, 0, 64))
            
            # 2. Swinging feet (Draw on top of shadow)
            left_foot_y = math.sin(walk_cycle) * 12
            right_foot_y = math.sin(walk_cycle + math.pi) * 12
            
            # Simple feet rectangles
            draw.rounded_rectangle([cx - 17, cy - 15 + left_foot_y, cx - 3, cy + 11 + left_foot_y], radius=6, fill=(200, 144, 104, 255))
            draw.rounded_rectangle([cx + 3, cy - 15 + right_foot_y, cx + 17, cy + 11 + right_foot_y], radius=6, fill=(200, 144, 104, 255))
            
            # 3. Body bobbing
            body_bob = abs(math.sin(walk_cycle)) * 3
            
            # Paste character
            paste_x = cx - char_w // 2
            paste_y = int(cy - char_img.height + 15 - body_bob)
            
            frame.paste(char_img, (paste_x, paste_y), char_img)
            
            frames.append(frame)
            
        # Save GIF
        frames[0].save(
            r"assets\images\yatra_journey_full.gif",
            save_all=True,
            append_images=frames[1:],
            duration=40, # ~25 FPS
            loop=0
        )
        print("Full GIF generated successfully!")
        
    except Exception as e:
        print("Error generating GIF:", e)

if __name__ == "__main__":
    generate_yatra_gif()
