"""Genera el atlas de racimos de hojas del estilo anime (Etapa C, revisión C2).

Dibuja, con formas vectoriales y semilla fija, cuatro racimos de hojas lanceoladas en escala de grises
(el shader les da el color de cada especie). El valor más claro va arriba y hacia fuera del racimo y el
más oscuro dentro, para que el racimo tenga volumen propio; el borde del racimo queda dentado por las
puntas de las hojas. No usa fotografías ni imágenes generadas.

Uso: python3 tools/c2/generar_racimos.py   (escribe assets/anime/selva_c2/racimo_hojas.png)
"""
import math
import os
import random

from PIL import Image, ImageDraw

CELDA = 512
SS = 2  # supermuestreo
SALIDA = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "anime", "selva_c2", "racimo_hojas.png")

# variantes: (semilla, número de hojas, largo mín/máx, proporción ancho/largo)
VARIANTES = [
    (11, 130, 80, 115, (0.30, 0.40)),   # racimo denso de hoja media
    (23, 110, 92, 130, (0.24, 0.32)),   # hoja más larga y estrecha
    (37, 150, 70, 100, (0.36, 0.46)),   # hoja redondeada, muy denso
    (51, 100, 86, 122, (0.28, 0.36)),   # racimo abierto, borde más irregular
]


def hoja(cx, cy, ang, largo, ancho):
    """Polígono de una hoja lanceolada con punta, desde el pecíolo (cx, cy) hacia 'ang'."""
    pts_i, pts_d = [], []
    dx, dy = math.cos(ang), math.sin(ang)
    nx, ny = -dy, dx
    for k in range(17):
        t = k / 16.0
        w = ancho * 0.5 * (math.sin(math.pi * t) ** 0.75) * (1.0 - 0.25 * t)
        px, py = cx + dx * largo * t, cy + dy * largo * t
        pts_i.append((px + nx * w, py + ny * w))
        pts_d.append((px - nx * w, py - ny * w))
    return pts_i + pts_d[::-1]


def racimo(semilla, n, lmin, lmax, prop):
    rng = random.Random(semilla)
    t = CELDA * SS
    img = Image.new("RGBA", (t, t), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = t * 0.5
    radio = t * 0.31
    hojas = []
    for _ in range(n):
        a = rng.uniform(0, math.tau)
        r = radio * math.sqrt(rng.random())
        # el contorno del racimo es irregular: unos lóbulos empujan las hojas hacia fuera
        lobulo = 1.0 + 0.18 * math.sin(a * 3.0 + semilla) + 0.1 * math.sin(a * 5.0 + semilla * 0.7)
        px, py = c + math.cos(a) * r * lobulo, c + math.sin(a) * r * lobulo
        dir_ = a + rng.uniform(-0.55, 0.55) if r > radio * 0.15 else rng.uniform(0, math.tau)
        largo = rng.uniform(lmin, lmax) * SS
        ancho = largo * rng.uniform(*prop)
        # valor: más claro arriba-izquierda (luz) y hacia fuera; más oscuro en el interior
        luz = 0.5 + 0.5 * (-(math.cos(a) * 0.45 + math.sin(a) * 0.9))
        v = 0.48 + 0.3 * (r / radio) + 0.16 * luz + rng.uniform(-0.05, 0.05)
        # la hoja se centra en el punto (no nace en él): el centro del racimo queda cubierto
        px, py = px - math.cos(dir_) * largo * 0.45, py - math.sin(dir_) * largo * 0.45
        hojas.append((r, px, py, dir_, largo, ancho, min(max(v, 0.45), 1.0)))
    hojas.sort(key=lambda h: h[0])  # primero las interiores; las exteriores las tapan
    for r, px, py, ang, largo, ancho, v in hojas:
        g = int(v * 255)
        d.polygon(hoja(px, py, ang, largo, ancho), fill=(g, g, g, 255))
        # nervio central, un poco más oscuro
        gm = int(v * 0.78 * 255)
        d.line([(px, py), (px + math.cos(ang) * largo * 0.85, py + math.sin(ang) * largo * 0.85)], fill=(gm, gm, gm, 255), width=2 * SS)
    return img.resize((CELDA, CELDA), Image.LANCZOS)


def main():
    atlas = Image.new("RGBA", (CELDA * 2, CELDA * 2), (0, 0, 0, 0))
    for i, var in enumerate(VARIANTES):
        atlas.alpha_composite(racimo(*var), ((i % 2) * CELDA, (i // 2) * CELDA))
    # el color de los píxeles transparentes se rellena con el gris medio para que los mipmaps no
    # oscurezcan el borde del racimo
    px = atlas.load()
    for y in range(atlas.height):
        for x in range(atlas.width):
            r, g, b, a = px[x, y]
            if a == 0:
                px[x, y] = (150, 150, 150, 0)
    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
    atlas.save(SALIDA)
    print("escrito", os.path.abspath(SALIDA))


if __name__ == "__main__":
    main()
