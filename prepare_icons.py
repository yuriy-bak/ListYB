# file: make_listyb_icons.py
from PIL import Image, ImageDraw
import math, os, zipfile, io, sys, shutil

# ====== Параметры ======
BASE_SIZE = 1024
STROKE = 20
COLOR = (22, 56, 43, 255)  # монохромный «карандашный» цвет
OUT_DIR = "icons_out"
ZIP_NAME = "listyb_icons_monochrome_nocompress.zip"

def draw_icon():
    img = Image.open('icon.png')
    # img = Image.new('RGBA', (BASE_SIZE, BASE_SIZE), (0,0,0,0))
    # draw = ImageDraw.Draw(img)

    # margin = 120
    # rr = 60
    # # Страница блокнота
    # draw.rounded_rectangle((margin, margin+80, BASE_SIZE-margin, BASE_SIZE-margin),
    #                        rr, outline=COLOR, width=STROKE)
    # # Кольца сверху
    # ring_spacing = 150
    # ring_y0 = margin + 20
    # for i in range(5):
    #     cx = margin + 120 + i*ring_spacing
    #     draw.rounded_rectangle((cx-28, ring_y0-28, cx+28, ring_y0+28),
    #                            16, outline=COLOR, width=STROKE//2)
    # # Чекбоксы
    # box_size = 90
    # start_x = margin + 40
    # start_y = margin + 180
    # row_h   = 160
    # checks = [True, True, True, False]
    # for idx, checked in enumerate(checks):
    #     x0 = start_x
    #     y0 = start_y + idx*row_h
    #     draw.rounded_rectangle((x0, y0, x0+box_size, y0+box_size),
    #                            12, outline=COLOR, width=STROKE//2)
    #     if checked:
    #         cx = x0 + box_size*0.2
    #         cy = y0 + box_size*0.55
    #         p2 = (cx + box_size*0.25, cy + box_size*0.25)
    #         p3 = (x0 + box_size*0.8,  y0 + box_size*0.2)
    #         draw.line([(cx,cy), p2], fill=COLOR, width=STROKE//2)
    #         draw.line([p2, p3],     fill=COLOR, width=STROKE//2)

    # # Волнистые линии (текст)
    # text_x = start_x + box_size + 60
    # for idx in range(4):
    #     y = start_y + idx*row_h + box_size*0.5
    #     amplitude = 18; wavelength = 60
    #     length = BASE_SIZE - margin - text_x - 220
    #     pts = []
    #     for x in range(0, length, 6):
    #         px = text_x + x
    #         py = int(y + amplitude*math.sin(2*math.pi*x/wavelength))
    #         pts.append((px, py))
    #     draw.line(pts, fill=COLOR, width=STROKE//2)

    # # Ручка
    # pen_x = BASE_SIZE - margin - 220
    # pen_y0 = margin + 180
    # pen_y1 = BASE_SIZE - margin - 120
    # draw.rounded_rectangle((pen_x, pen_y0, pen_x+110, pen_y1),
    #                        40, outline=COLOR, width=STROKE//2)
    # # Клипса
    # draw.rectangle((pen_x+10, pen_y0+40, pen_x+130, pen_y0+90),
    #                outline=COLOR, width=STROKE//2)
    # # Наконечник
    # draw.polygon([(pen_x, pen_y1), (pen_x+110, pen_y1), (pen_x+70, pen_y1+120)],
    #              outline=COLOR)
    # # Центральная линия
    # draw.line([(pen_x+55, pen_y0+10), (pen_x+55, pen_y1+20)],
    #           fill=COLOR, width=STROKE//3)

    return img

def main():
    # 1) Рисуем мастер
    os.makedirs(OUT_DIR, exist_ok=True)
    for sub in ["android","ios","web","master"]:
        os.makedirs(os.path.join(OUT_DIR, sub), exist_ok=True)

    img = draw_icon()
    master_path = os.path.join(OUT_DIR, "master", "icon-master-1024.png")
    img.save(master_path, "PNG")

    # 2) SVG-заглушка (если нужен чистый вектор — скажи, добавлю трассировку)
    svg_path = os.path.join(OUT_DIR, "icon.svg")
    with open(svg_path, "w") as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024"></svg>')

    # 3) Ресайзы
    sizes_android = {'mdpi':48, 'hdpi':72, 'xhdpi':96, 'xxhdpi':144, 'xxxhdpi':192}
    sizes_ios     = {'1x':60, '2x':120, '3x':180}
    sizes_web     = {'192':192, '512':512}

    for k, sz in sizes_android.items():
        os.makedirs(os.path.join(OUT_DIR,"android",f"mipmap-{k}"), exist_ok=True)
        img.resize((sz,sz), Image.LANCZOS).save(os.path.join(OUT_DIR,"android",f"mipmap-{k}", "ic_launcher.png"), "PNG")
    for k, sz in sizes_ios.items():
        img.resize((sz,sz), Image.LANCZOS).save(os.path.join(OUT_DIR,"ios",f"icon-{k}.png"), "PNG")
    for k, sz in sizes_web.items():
        img.resize((sz,sz), Image.LANCZOS).save(os.path.join(OUT_DIR,"web",f"icon-web-{k}.png"), "PNG")

    # 4) ZIP без сжатия + проверка целостности
    zip_path = ZIP_NAME
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_STORED) as z:
        z.write(svg_path, arcname="icon.svg")
        z.write(master_path, arcname="master/icon-master-1024.png")
        for folder in ["android","ios","web"]:
            full = os.path.join(OUT_DIR, folder)
            for fn in sorted(os.listdir(full)):
                z.write(os.path.join(full, fn), arcname=f"{folder}/{fn}")

    # Проверяем central directory
    with zipfile.ZipFile(zip_path, "r") as z:
        bad = z.testzip()
        if bad:
            raise RuntimeError(f"Проблема в архиве, повреждён файл: {bad}")

    print("OK:", zip_path, "=>", OUT_DIR)

if __name__ == "__main__":
    main()
