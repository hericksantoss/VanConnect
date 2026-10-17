"""Gera o ícone do Van Connect a partir do logo (assets/logo.png)."""
import sys
from PIL import Image, ImageDraw, ImageFilter

raiz = sys.argv[1]
logo = Image.open(f'{raiz}/assets/logo.png').convert('RGB')

# Só a van (sem o texto e sem as ondas de sinal do logo).
van = logo.crop((88, 6, 432, 297)).convert('RGBA')
px = van.load()
for y in range(van.height):
    for x in range(van.width):
        r, g, b, _ = px[x, y]
        # Ondas do logo (direita) e o topo azul do texto "Connect" (embaixo).
        if (x + 88 > 405 and y + 6 > 245) or (y + 6 > 278 and b > r + 30):
            px[x, y] = (255, 255, 255, 255)

# Fundo branco do recorte vira transparente (com borda suave).
for y in range(van.height):
    for x in range(van.width):
        r, g, b, _ = px[x, y]
        m = min(r, g, b)
        if m > 238:
            px[x, y] = (255, 255, 255, 0)
        elif m > 222:
            px[x, y] = (r, g, b, int(255 * (238 - m) / 16))

N = 1024
AZUL = (30, 127, 216)
MARINHO = (16, 33, 63)
AMARELO = (251, 192, 45)


def gradiente(n):
    g = Image.new('RGB', (n, n))
    d = ImageDraw.Draw(g)
    for y in range(n):
        t = y / (n - 1)
        cor = tuple(int(AZUL[i] * (1 - t) + MARINHO[i] * t * 0.55 + AZUL[i] * t * 0.45) for i in range(3))
        d.line([(0, y), (n, y)], fill=cor)
    return g


def frente(n, escala):
    """Círculo branco com a van e as ondas de sinal (centralizados)."""
    camada = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    c = n / 2
    raio = n * 0.34 * escala

    sombra = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    ImageDraw.Draw(sombra).ellipse([c - raio, c - raio + n * 0.012, c + raio, c + raio + n * 0.012], fill=(6, 20, 45, 90))
    camada.alpha_composite(sombra.filter(ImageFilter.GaussianBlur(n * 0.012)))
    ImageDraw.Draw(camada).ellipse([c - raio, c - raio, c + raio, c + raio], fill=(255, 255, 255, 255))

    largura = int(raio * 1.36)
    v = van.resize((largura, int(van.height * largura / van.width)), Image.LANCZOS)
    topo = int(c - v.height / 2 + raio * 0.16)
    camada.alpha_composite(v, (int(c - v.width / 2), topo))

    # Ondas de sinal (como no logo), em azul, saindo do teto da van.
    d = ImageDraw.Draw(camada)
    ox, oy = c, topo - raio * 0.02
    espessura = max(4, int(raio * 0.07))
    for rr in [0.20, 0.36, 0.52]:
        r = raio * rr
        d.arc([ox - r, oy - r, ox + r, oy + r], start=-135, end=-45, fill=AZUL + (255,), width=espessura)
    return camada


# Ícone completo (iOS e Android antigo): fundo azul + frente.
icone = gradiente(N).convert('RGBA')
icone.alpha_composite(frente(N, 1.14))
icone.convert('RGB').save(f'{raiz}/icone/icone.png')

# Ícone adaptativo do Android: a frente fica dentro da área segura (66%).
frente(N, 0.86).save(f'{raiz}/icone/frente.png')
gradiente(N).save(f'{raiz}/icone/fundo.png')
print('ok')
