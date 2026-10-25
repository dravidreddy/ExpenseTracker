import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

repo_path = r"c:\Users\dravi\OneDrive\Desktop\ExpenseTracker"
font_path = os.path.join(repo_path, "assets", "fonts", "Outfit-Variable.ttf")
src_icon_path = os.path.join(repo_path, "assets", "images", "app_logo.png")

os.makedirs(os.path.join(repo_path, "store_assets", "google_play"), exist_ok=True)
os.makedirs(os.path.join(repo_path, "store_assets", "apple_app_store"), exist_ok=True)
os.makedirs(os.path.join(repo_path, "store_assets", "marketing"), exist_ok=True)

# ─────────────────────────────────────────────────────────────────────────────
# 1. High-Res App Icons
# ─────────────────────────────────────────────────────────────────────────────
logo_img = Image.open(src_icon_path).convert("RGBA")

# Google Play 512x512
icon_512 = logo_img.resize((512, 512), Image.Resampling.LANCZOS)
icon_512.save(os.path.join(repo_path, "store_assets", "google_play", "app_icon_512.png"), "PNG")

# App Store 1024x1024
icon_1024 = logo_img.resize((1024, 1024), Image.Resampling.LANCZOS)
icon_1024.save(os.path.join(repo_path, "store_assets", "apple_app_store", "app_icon_1024.png"), "PNG")
print("Saved 512x512 and 1024x1024 high-res icons.")

# ─────────────────────────────────────────────────────────────────────────────
# 2. Google Play Feature Graphic (1024 x 500 px, 24-bit RGB, No Alpha)
# ─────────────────────────────────────────────────────────────────────────────
fg_w, fg_h = 1024, 500
# Gradient background: Obsidian #0A0A0E to deep graphite #141419
base_bg = Image.new("RGB", (fg_w, fg_h), (10, 10, 14))
draw_bg = ImageDraw.Draw(base_bg)

# Subtle radial glow behind the emblem
glow = Image.new("RGBA", (fg_w, fg_h), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow)
center_x, center_y = 230, 250
for r in range(240, 20, -10):
    alpha = int(18 * (1.0 - r / 240.0))
    glow_draw.ellipse(
        [center_x - r, center_y - r, center_x + r, center_y + r],
        fill=(255, 255, 255, alpha)
    )
glow = glow.filter(ImageFilter.GaussianBlur(15))
base_bg.paste(Image.composite(Image.new("RGB", (fg_w, fg_h), (255, 255, 255)), base_bg, glow.split()[3]), (0, 0))

# Place logo emblem on left
emblem_size = 310
emblem = logo_img.resize((emblem_size, emblem_size), Image.Resampling.LANCZOS)
# Add subtle luxury border around emblem
emblem_box = Image.new("RGBA", (emblem_size + 16, emblem_size + 16), (0, 0, 0, 0))
emblem_box_draw = ImageDraw.Draw(emblem_box)
emblem_box_draw.rounded_rectangle(
    [0, 0, emblem_size + 15, emblem_size + 15],
    radius=68,
    outline=(255, 255, 255, 45),
    width=2
)
emblem_mask = Image.new("L", (emblem_size, emblem_size), 0)
ImageDraw.Draw(emblem_mask).rounded_rectangle([0, 0, emblem_size, emblem_size], radius=60, fill=255)
emblem_box.paste(emblem, (8, 8), emblem_mask)

base_bg.paste(emblem_box, (85, (fg_h - (emblem_size + 16)) // 2), emblem_box)

# Right-hand Typography & Value Proposition
draw = ImageDraw.Draw(base_bg)
font_title = ImageFont.truetype(font_path, 46)
font_sub = ImageFont.truetype(font_path, 21)
font_badge = ImageFont.truetype(font_path, 15)

tx = 445
ty = 115

# "EXPENSE TRACKER"
draw.text((tx, ty), "EXPENSE TRACKER", font=font_title, fill=(255, 255, 255))

# Subtitle / Hook
draw.text((tx, ty + 68), "Zero Friction. 100% Offline & Private.", font=font_sub, fill=(180, 185, 195))
draw.text((tx, ty + 102), "Fast local expense tracking with zero cloud tracking.", font=font_sub, fill=(120, 125, 138))

# Pill badges
badges = [
    ("NO CLOUD ACCOUNT", (30, 32, 40), (220, 225, 235)),
    ("SQLCIPHER ENCRYPTED", (22, 35, 26), (90, 220, 130)),
    ("BIOMETRIC LOCK", (35, 30, 22), (235, 180, 80)),
    ("CSV EXPORT", (28, 30, 42), (130, 175, 245)),
]

bx = tx
by = ty + 165
for label, bg_col, text_col in badges:
    bbox = draw.textbbox((0, 0), label, font=font_badge)
    pw = bbox[2] - bbox[0] + 28
    ph = 32
    if bx + pw > fg_w - 30:
        bx = tx
        by += ph + 10
    draw.rounded_rectangle([bx, by, bx + pw, by + ph], radius=16, fill=bg_col, outline=(text_col[0], text_col[1], text_col[2], 50), width=1)
    draw.text((bx + 14, by + 7), label, font=font_badge, fill=text_col)
    bx += pw + 12

feature_graphic_path = os.path.join(repo_path, "store_assets", "google_play", "feature_graphic_1024x500.png")
base_bg.save(feature_graphic_path, "PNG")
print("Saved Google Play Feature Graphic (1024x500).")

# ─────────────────────────────────────────────────────────────────────────────
# 3. Store Showcase Screenshots (1080 x 1920 px, 9:16 aspect ratio)
# ─────────────────────────────────────────────────────────────────────────────
screenshots_data = [
    {
        "filename": "screenshot_1_zero_friction.png",
        "tagline": "EFFORTLESS ENTRY",
        "headline": "Track Expenses In Under 3s",
        "detail": "Instant numpad input, smart categories, zero lag.",
        "accent": (255, 255, 255),
        "ui_card_title": "Quick Add",
        "items": [
            ("Coffee & Pastry", "Food & Dining", "-$4.50", (255, 100, 100)),
            ("Subway Transit Card", "Transport", "-$22.00", (255, 100, 100)),
            ("Freelance Milestone", "Income", "+$850.00", (80, 220, 130)),
            ("Grocery Market Run", "Groceries", "-$64.20", (255, 100, 100)),
        ]
    },
    {
        "filename": "screenshot_2_insights.png",
        "tagline": "CLEAR INSIGHTS",
        "headline": "Dynamic Spending Analytics",
        "detail": "Break down monthly velocity and category trends.",
        "accent": (90, 200, 250),
        "ui_card_title": "Monthly Breakdown",
        "items": [
            ("Food & Dining", "38% of total spending", "$480.50", (90, 200, 250)),
            ("Housing & Utilities", "29% of total spending", "$370.00", (160, 130, 255)),
            ("Transport & Fuel", "18% of total spending", "$225.80", (255, 180, 80)),
            ("Entertainment", "15% of total spending", "$190.10", (80, 220, 130)),
        ]
    },
    {
        "filename": "screenshot_3_privacy.png",
        "tagline": "RADICAL PRIVACY",
        "headline": "100% Offline & Encrypted",
        "detail": "No servers. No data tracking. SQLCipher & Biometrics.",
        "accent": (80, 220, 130),
        "ui_card_title": "Security & Encryption",
        "items": [
            ("Local Database", "256-bit AES SQLCipher", "ENCRYPTED", (80, 220, 130)),
            ("Biometric Authentication", "FaceID / Fingerprint", "ACTIVE", (80, 220, 130)),
            ("Cloud Synchronization", "Zero External Traffic", "OFFLINE", (160, 170, 185)),
            ("Data Brokers & Ad Tracking", "Zero Telemetry SDKs", "BLOCKED", (80, 220, 130)),
        ]
    },
    {
        "filename": "screenshot_4_export.png",
        "tagline": "DATA FREEDOM",
        "headline": "Export & Backup Anytime",
        "detail": "Full CSV spreadsheet export with multi-currency.",
        "accent": (235, 180, 80),
        "ui_card_title": "Export & Currency",
        "items": [
            ("CSV Spreadsheet", "Full transaction history", "EXPORT", (235, 180, 80)),
            ("Currency Selector", "USD, EUR, GBP, INR, JPY...", "SELECTED", (160, 170, 185)),
            ("Local Device Backup", "Encrypted snapshot file", "READY", (235, 180, 80)),
            ("Data Portability", "Zero vendor lock-in", "100%", (80, 220, 130)),
        ]
    }
]

sc_w, sc_h = 1080, 1920
font_sc_tag = ImageFont.truetype(font_path, 28)
font_sc_head = ImageFont.truetype(font_path, 58)
font_sc_sub = ImageFont.truetype(font_path, 32)
font_card_head = ImageFont.truetype(font_path, 34)
font_item_name = ImageFont.truetype(font_path, 28)
font_item_sub = ImageFont.truetype(font_path, 22)
font_item_val = ImageFont.truetype(font_path, 28)

for idx, sc_info in enumerate(screenshots_data, 1):
    sc_img = Image.new("RGB", (sc_w, sc_h), (11, 12, 16))
    sc_draw = ImageDraw.Draw(sc_img)
    
    # Top banner background glow
    top_glow = Image.new("RGBA", (sc_w, 400), (0, 0, 0, 0))
    glow_d = ImageDraw.Draw(top_glow)
    glow_d.ellipse([sc_w//2 - 350, -100, sc_w//2 + 350, 300], fill=(sc_info["accent"][0], sc_info["accent"][1], sc_info["accent"][2], 30))
    top_glow = top_glow.filter(ImageFilter.GaussianBlur(35))
    sc_img.paste(Image.composite(Image.new("RGB", (sc_w, 400), sc_info["accent"]), sc_img.crop((0, 0, sc_w, 400)), top_glow.split()[3]), (0, 0))
    
    # Top Tagline
    sc_draw.text((sc_w//2, 160), sc_info["tagline"], font=font_sc_tag, fill=sc_info["accent"], anchor="mm")
    
    # Large Headline
    sc_draw.text((sc_w//2, 240), sc_info["headline"], font=font_sc_head, fill=(255, 255, 255), anchor="mm")
    
    # Subtitle
    sc_draw.text((sc_w//2, 320), sc_info["detail"], font=font_sc_sub, fill=(155, 162, 175), anchor="mm")
    
    # Phone Frame Mockup in Obsidian/Slate
    frame_x1, frame_y1 = 90, 430
    frame_x2, frame_y2 = sc_w - 90, sc_h - 100
    frame_w = frame_x2 - frame_x1
    frame_h = frame_y2 - frame_y1
    
    # Outer device bezel
    sc_draw.rounded_rectangle([frame_x1, frame_y1, frame_x2, frame_y2], radius=64, fill=(18, 19, 25), outline=(45, 48, 62), width=3)
    
    # Inner screen
    screen_pad = 18
    sx1, sy1 = frame_x1 + screen_pad, frame_y1 + screen_pad
    sx2, sy2 = frame_x2 - screen_pad, frame_y2 - screen_pad
    sc_draw.rounded_rectangle([sx1, sy1, sx2, sy2], radius=50, fill=(8, 8, 10))
    
    # Dynamic Island / Notch
    sc_draw.rounded_rectangle([sc_w//2 - 80, sy1 + 14, sc_w//2 + 80, sy1 + 44], radius=15, fill=(18, 19, 24))
    
    # Mini Header inside UI
    ui_y = sy1 + 80
    sc_draw.text((sx1 + 45, ui_y), sc_info["ui_card_title"], font=font_card_head, fill=(255, 255, 255))
    sc_draw.text((sx2 - 45, ui_y + 4), "Offline Mode", font=font_item_sub, fill=(80, 220, 130), anchor="ra")
    
    # Balance / Total Metric Card
    ui_y += 70
    sc_draw.rounded_rectangle([sx1 + 35, ui_y, sx2 - 35, ui_y + 130], radius=24, fill=(22, 23, 30), outline=(40, 42, 54), width=1)
    sc_draw.text((sx1 + 65, ui_y + 30), "October Net Spending", font=font_item_sub, fill=(150, 155, 170))
    sc_draw.text((sx1 + 65, ui_y + 65), "$1,265.40", font=font_sc_head, fill=(255, 255, 255))
    sc_draw.rounded_rectangle([sx2 - 185, ui_y + 40, sx2 - 65, ui_y + 85], radius=14, fill=(35, 40, 52))
    sc_draw.text((sx2 - 125, ui_y + 62), "USD ($)", font=font_item_sub, fill=(220, 225, 240), anchor="mm")
    
    # Transaction / Item List inside Phone
    ui_y += 170
    sc_draw.text((sx1 + 45, ui_y), "Recent Activity", font=font_item_sub, fill=(140, 145, 160))
    ui_y += 40
    
    for name, sub, val, val_col in sc_info["items"]:
        item_h = 100
        sc_draw.rounded_rectangle([sx1 + 35, ui_y, sx2 - 35, ui_y + item_h], radius=20, fill=(18, 19, 25), outline=(32, 34, 44), width=1)
        
        # Category icon circle
        sc_draw.ellipse([sx1 + 55, ui_y + 24, sx1 + 107, ui_y + 76], fill=(30, 32, 42))
        sc_draw.text((sx1 + 81, ui_y + 50), name[0], font=font_item_name, fill=sc_info["accent"], anchor="mm")
        
        # Item title & subtitle
        sc_draw.text((sx1 + 125, ui_y + 24), name, font=font_item_name, fill=(255, 255, 255))
        sc_draw.text((sx1 + 125, ui_y + 58), sub, font=font_item_sub, fill=(130, 135, 148))
        
        # Amount / Status Value
        sc_draw.text((sx2 - 60, ui_y + 50), val, font=font_item_val, fill=val_col, anchor="rm")
        
        ui_y += item_h + 16
        if ui_y > sy2 - 140:
            break
            
    # Bottom quick action pill
    action_y = sy2 - 100
    sc_draw.rounded_rectangle([sx1 + 60, action_y, sx2 - 60, action_y + 68], radius=34, fill=sc_info["accent"])
    text_color = (10, 10, 12) if sum(sc_info["accent"]) > 400 else (255, 255, 255)
    sc_draw.text((sc_w//2, action_y + 34), "+ Add New Expense", font=font_item_name, fill=text_color, anchor="mm")

    # Save to both Google Play and Apple App Store directories
    out_gp = os.path.join(repo_path, "store_assets", "google_play", sc_info["filename"])
    out_ios = os.path.join(repo_path, "store_assets", "apple_app_store", sc_info["filename"])
    sc_img.save(out_gp, "PNG")
    sc_img.save(out_ios, "PNG")
    print(f"Generated screenshot {idx}: {sc_info['filename']}")

print("All visual store assets successfully created!")
