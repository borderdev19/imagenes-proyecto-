"""
locomocion_heroe.py — Corrección de la caminata del Pollo Amarillo (modelo de Meshy, v10+).

Diagnóstico (C3, 2026-10-31): el esqueleto se colocó con articulaciones simétricas y el modelo de Meshy
está de pie en una guardia abierta y asimétrica (pie izquierdo 18 cm por delante, punta del pie izquierdo
25° hacia fuera y la del derecho 43°). Tobillos y rodillas quedaban 6–14 cm fuera del eje real de la pierna,
así que las piernas se doblaban por donde no hay articulación y las botas giraban alrededor de un punto
fuera del tobillo. Además las animaciones de desplazamiento eran cuatro poses por rotación directa (sin
contacto con el suelo): en «caminar» ningún pie toca el suelo durante el 20 % del ciclo y el pie apoyado se
hunde hasta 5 cm, las botas conservaban el giro de la guardia y la zancada no correspondía a la velocidad.

Este script trabaja sobre blender/characters/pollo_amarillo.blend (la malla, las texturas y los pesos del
tronco, los brazos y la cabeza no se tocan):
  1. Recoloca las articulaciones de las piernas (cadera, rodilla, tobillo, punta) en el eje de cada pierna,
     medido sobre la malla.
  2. Recalcula los pesos solo de la parte baja (z < 0,92 m, fundido hasta 0,80 m) con el calor de Blender.
  3. Regenera las 11 acciones de siempre con chicken_rig.py (mismas definiciones; necesario porque cambió la
     pose de reposo de las piernas).
  4. Rehace «idle», «walk» y «run» con pies plantados: las trayectorias de los pies se calculan (apoyo
     lineal sin deslizamiento, balanceo de talón y de punta, despegue y altura de paso) y las piernas se
     resuelven con IK analítica de dos huesos (rodilla hacia la punta de la bota) directamente a claves de
     rotación por fotograma (el GLB no lleva restricciones ni IK en tiempo real). La pelvis sube y baja, gira y se desplaza con el paso; tronco, brazos,
     cabeza y cola contrarrotan.
  5. Exporta assets/characters/pollo_amarillo.glb con los mismos ajustes que build_hero_meshy.py.

Uso:  blender -b blender/characters/pollo_amarillo.blend --python blender/scripts/locomocion_heroe.py
      (SIN_EXPORTAR=1 para solo comprobar; GUARDAR=ruta.blend guarda una copia para revisarla;
       INFORME=ruta.json escribe las medidas de cada ciclo)
"""
import os, sys, math, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Vector, Matrix, Euler, Quaternion
import chicken_rig as RIG
import chicken_lib as L

# HeroAnimator de build_hero_meshy.py (copiado aquí para no importar char_v2_lib/sdf_lib): mismo cierre de
# muslos para las acciones que siguen siendo por rotación directa. walk/run/idle ya no lo usan en las piernas.
ADDUCT = {"idle": 7.0, "walk": 9.0, "run": 8.0}
STRIDE = {"walk": 1.25, "run": 1.1}


class HeroAnimator(RIG.Animator):
    def key(self, frame, pose, loc=None):
        act = self.rig.animation_data.action.name if self.rig.animation_data.action else ""
        if act in ADDUCT:
            pose = dict(pose)
            a = ADDUCT[act]
            k = STRIDE.get(act, 1.0)
            for s, sg in (("L", 1.0), ("R", -1.0)):
                tx, ty, tz = pose.get(f"thigh.{s}", (0, 0, 0))
                pose[f"thigh.{s}"] = (tx * k, ty + a * sg, tz)
                sx, sy, sz = pose.get(f"shin.{s}", (0, 0, 0))
                pose[f"shin.{s}"] = (sx * k, sy, sz)
                fx, fy, fz = pose.get(f"foot.{s}", (0, 0, 0))
                pose[f"foot.{s}"] = (fx, fy - a * sg, fz - 7.0 * sg)
        super().key(frame, pose, loc)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_GLB = os.path.join(ROOT, "assets", "characters", "pollo_amarillo.glb")
OUT_BLEND = os.path.join(ROOT, "blender", "characters", "pollo_amarillo.blend")

# --- 1. articulaciones de las piernas medidas sobre la malla (Blender: -Y delante, +X izquierda) -------
# Cortes horizontales de la malla: centro de la bota a 0,14–0,22 m, de la pernera a 0,38–0,46 m y del
# muslo a 0,54–0,62 m; talón y punta por análisis de componentes principales de la suela.
PIERNAS = {
    "L": dict(hip=(0.10, -0.02, 0.71), knee=(0.19, -0.05, 0.42), ankle=(0.272, -0.07, 0.115), toe=(0.363, -0.235, 0.04)),
    "R": dict(hip=(-0.10, -0.02, 0.71), knee=(-0.165, 0.04, 0.42), ankle=(-0.228, 0.085, 0.115), toe=(-0.363, -0.038, 0.04)),
}
# suela de cada bota en reposo: talón, metatarso (70 %) y punta; giro de la punta hacia fuera (grados)
SUELA = {
    "L": dict(heel=(0.245, 0.012), toe=(0.392, -0.297), yaw=25.4),
    "R": dict(heel=(-0.178, 0.158), toe=(-0.409, -0.087), yaw=43.3),
}
LADO = {"L": 1.0, "R": -1.0}

# --- parámetros de los ciclos ------------------------------------------------------------------------
# zancada = metros que avanza el cuerpo en un ciclo completo (dos pasos); el controlador del juego
# (cinematic_player.gd) reproduce cada ciclo a la velocidad que hace coincidir zancada y desplazamiento.
CICLOS = {
    "walk": dict(frames=24, zancada=1.10, apoyo=0.60, linea=0.115, punta_fuera=8.0, centro=-0.015,
                 talon=16.0, despegue=-32.0, altura_paso=0.075, pelvis=-0.036, bob=0.034, sube_en=0.30,
                 giro_pelvis=6.0, ladeo=0.012, inclina=5.0),
    "run": dict(frames=16, zancada=2.00, apoyo=0.30, linea=0.095, punta_fuera=6.0, centro=0.03,
                talon=6.0, despegue=-42.0, altura_paso=0.19, forma_paso=0.8, pico_paso=0.75, pelvis=-0.068, bob=0.03, sube_en=0.55,
                giro_pelvis=9.0, ladeo=0.008, inclina=14.0),
}
ALCANCE = 0.985   # fracción máxima de la longitud de la pierna (rodilla nunca bloqueada del todo)


def _rig_body():
    rig = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
    body = [o for o in bpy.data.objects if o.type == 'MESH'][0]
    return rig, body


# ------------------------------------------------------------------ 1-2. esqueleto y pesos
def recolocar_piernas(rig):
    bpy.ops.object.select_all(action='DESELECT')
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    eb = rig.data.edit_bones
    for s, j in PIERNAS.items():
        for name, a, b in (("thigh", "hip", "knee"), ("shin", "knee", "ankle"), ("foot", "ankle", "toe")):
            bone = eb[f"{name}.{s}"]
            bone.head = Vector(j[a])
            bone.tail = Vector(j[b])
            bone.roll = 0.0
    bpy.ops.object.mode_set(mode='OBJECT')


def recalcular_pesos_bajos(rig, body, z_bajo=0.80, z_alto=0.92):
    """Pesos nuevos (calor) por debajo de z_bajo, los de antes por encima de z_alto y mezcla lineal entre
    medias. Así el tronco, los brazos y la cabeza conservan exactamente su deformación."""
    names = [g.name for g in body.vertex_groups]
    viejos = [{body.vertex_groups[g.group].name: g.weight for g in v.groups} for v in body.data.vertices]
    tmp = body.copy()
    tmp.data = body.data.copy()
    bpy.context.scene.collection.objects.link(tmp)
    tmp.vertex_groups.clear()
    for m in list(tmp.modifiers):
        tmp.modifiers.remove(m)
    tmp.parent = None
    bpy.ops.object.select_all(action='DESELECT')
    tmp.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')
    nuevos = [{tmp.vertex_groups[g.group].name: g.weight for g in v.groups} for v in tmp.data.vertices]
    me = tmp.data
    bpy.data.objects.remove(tmp)
    bpy.data.meshes.remove(me)
    ignorar = ("root", "band_tail")
    sin_peso = 0
    for i, v in enumerate(body.data.vertices):
        z = v.co.z
        t = min(1.0, max(0.0, (z_alto - z) / (z_alto - z_bajo)))   # 1 = pesos nuevos
        if t <= 0.0:
            continue
        nv = {k: w for k, w in nuevos[i].items() if k not in ignorar}
        tot = sum(nv.values())
        if tot < 1e-6:
            sin_peso += 1
            continue
        mezcla = {}
        for k, w in viejos[i].items():
            mezcla[k] = mezcla.get(k, 0.0) + w * (1.0 - t)
        for k, w in nv.items():
            mezcla[k] = mezcla.get(k, 0.0) + w / tot * t
        s = sum(mezcla.values())
        for g in list(v.groups):
            body.vertex_groups[g.group].remove([i])
        for k, w in mezcla.items():
            if w / s < 0.005:
                continue
            vg = body.vertex_groups.get(k) or body.vertex_groups.new(name=k)
            vg.add([i], w / s, 'REPLACE')
    # suavizado solo de los grupos de la parte baja
    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
    for g in ("hips", "tail", "thigh.L", "shin.L", "foot.L", "thigh.R", "shin.R", "foot.R"):
        if g in body.vertex_groups:
            body.vertex_groups.active_index = body.vertex_groups[g].index
            bpy.ops.object.vertex_group_smooth(group_select_mode='ACTIVE', factor=0.5, repeat=3)
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    # los vértices altos vuelven exactamente a sus pesos de antes (el suavizado no debe tocarlos)
    for i, v in enumerate(body.data.vertices):
        if v.co.z >= z_alto:
            for g in list(v.groups):
                body.vertex_groups[g.group].remove([i])
            for k, w in viejos[i].items():
                body.vertex_groups[k].add([i], w, 'REPLACE')
    print(f"[pesos] parte baja recalculada; vértices sin solución de calor (conservan los pesos de antes): {sin_peso}")


# ------------------------------------------------------------------ geometría del pie
class Pie:
    """Geometría de una bota en reposo y su colocación durante el ciclo (espacio del armature)."""

    def __init__(self, rig, s, punta_fuera):
        self.s = s
        sg = LADO[s]
        b = rig.data.bones[f"foot.{s}"]
        self.rest = b.matrix_local.copy()           # 4x4 en espacio del armature
        A0 = Vector(PIERNAS[s]["ankle"])
        su = SUELA[s]
        heel = Vector((su["heel"][0], su["heel"][1], 0.0))
        toe = Vector((su["toe"][0], su["toe"][1], 0.0))
        # bota rígida (sin hueso de dedos): el despegue gira sobre la puntera, no sobre el metatarso
        ball = heel.lerp(toe, 0.97)
        self.G0 = Vector((A0.x, A0.y, 0.0))         # proyección del tobillo en el suelo
        self.a = A0 - self.G0
        self.h = heel - self.G0
        self.b = ball - self.G0
        self.t = toe - self.G0
        # giro de la guardia -> punta casi recta (un poco hacia fuera)
        self.dyaw = math.radians((punta_fuera - su["yaw"]) * sg)
        self.Rz = Matrix.Rotation(self.dyaw, 3, 'Z')
        ang = math.radians(punta_fuera) * sg       # dirección final de la punta
        self.fwd = Vector((math.sin(ang), -math.cos(ang), 0.0))
        self.lat = Vector((math.cos(ang), math.sin(ang), 0.0))

    def _pitch(self, theta):
        # theta > 0: punta arriba (balanceo de talón); < 0: talón arriba (balanceo de punta)
        return Matrix.Rotation(-theta, 3, self.lat)

    def colocar(self, G, theta, pivote="auto"):
        """G: posición en el suelo del punto bajo el tobillo como si el pie estuviera plano.
        Devuelve (tobillo, rotación 3x3 del hueso del pie, puntos de la suela)."""
        P = self._pitch(theta)
        a, h, b, t = (self.Rz @ v for v in (self.a, self.h, self.b, self.t))
        if pivote == "auto":
            pivote = "heel" if theta > 0 else "ball"
        piv = h if pivote == "heel" else b
        base = G + piv
        tob = base + P @ (a - piv)
        suela = [base + P @ (p - piv) for p in (h, b, t)]
        rot = P @ self.Rz @ self.rest.to_3x3()
        return tob, rot, suela


def _suave(x):
    x = min(1.0, max(0.0, x))
    return x * x * (3 - 2 * x)


def _hermite(p0, p1, m0, m1, v):
    v2, v3 = v * v, v * v * v
    return (2 * v3 - 3 * v2 + 1) * p0 + (v3 - 2 * v2 + v) * m0 + (-2 * v3 + 3 * v2) * p1 + (v3 - v2) * m1


def trayectoria_pie(pie, c, fase, hip_y=0.0):
    """Posición del tobillo, rotación del pie y suela para una fase del ciclo (0 = apoyo del talón)."""
    S, beta = c["zancada"], c["apoyo"]
    sg = LADO[pie.s]
    y_front = c["centro"] - beta * S / 2.0
    y_back = c["centro"] + beta * S / 2.0
    x = c["linea"] * sg

    def stance(u):
        G = Vector((x, y_front + u * beta * S, 0.0))
        u1, u2 = 0.16, 0.50
        if u < u1:
            th = math.radians(c["talon"]) * (1.0 - _suave(u / u1))
        elif u < u2:
            th = 0.0
        else:
            k = (u - u2) / (1.0 - u2)
            th = math.radians(c["despegue"]) * (k ** 1.6)
        return pie.colocar(G, th)

    if fase < beta:
        tob, rot, suela = stance(fase / beta)
        return tob, rot, suela, True
    v = (fase - beta) / (1.0 - beta)
    t0, r0, _ = stance(1.0)
    # siguiente apoyo de talón (el cuerpo ya avanzó): mismo punto de partida del ciclo
    t1, r1, _ = stance(0.0)
    # velocidad del pie en los extremos = velocidad del suelo (hacia atrás) para empalmar sin tirones
    vel = Vector((0.0, S * (1.0 - beta), 0.0))
    pos = Vector([_hermite(t0[i], t1[i], vel[i], vel[i], v) for i in range(3)])
    # altura del paso: sube pronto (sacar la punta del suelo) y baja suave hacia el talón
    # pico de altura antes de la mitad en la carrera (el talón se recoge detrás del cuerpo)
    vv = min(1.0, v / 0.95) ** c.get("pico_paso", 1.0)
    lift = c["altura_paso"] * math.sin(math.pi * vv) ** c.get("forma_paso", 1.3) if v < 0.95 else 0.0
    pos.z += lift
    # orientación: de la punta abajo del despegue a la punta arriba del apoyo
    th0, th1 = math.radians(c["despegue"]), math.radians(c["talon"])
    th = th0 + (th1 - th0) * _suave(v * 1.15)
    P = pie._pitch(th)
    rot = P @ pie.Rz @ pie.rest.to_3x3()
    # empalme de la rotación con el apoyo en los dos extremos
    q = r0.to_quaternion().slerp(rot.to_quaternion(), _suave(v / 0.2)) if v < 0.2 else rot.to_quaternion()
    if v > 0.85:
        q = q.slerp(r1.to_quaternion(), _suave((v - 0.85) / 0.15))
    rot = q.to_matrix()
    # la bota en el aire nunca entra en el suelo (la puntera baja al girar)
    D = rot @ pie.rest.to_3x3().inverted()
    a = pie.a
    pmin = min((D @ (p - a)).z for p in (pie.h, pie.b, pie.t))
    if pos.z + pmin < 0.0:
        pos.z -= pos.z + pmin
    return pos, rot, None, False


# ------------------------------------------------------------------ IK analítica de dos huesos
REST = {}


def _reposo(rig):
    for s in ("L", "R"):
        j = {k: Vector(v) for k, v in PIERNAS[s].items()}
        su = SUELA[s]
        ang = math.radians(su["yaw"]) * LADO[s]
        REST[s] = dict(j=j, l1=(j["knee"] - j["hip"]).length, l2=(j["ankle"] - j["knee"]).length,
                       # la rodilla de la malla en reposo mira hacia donde apunta su bota
                       rodilla=Vector((math.sin(ang), -math.cos(ang), 0.0)),
                       Rt=rig.data.bones[f"thigh.{s}"].matrix_local.to_3x3(),
                       Rs=rig.data.bones[f"shin.{s}"].matrix_local.to_3x3(),
                       Rf=rig.data.bones[f"foot.{s}"].matrix_local.to_3x3())


def _marco(eje, ref):
    x = eje.normalized()
    y = (ref - x * ref.dot(x)).normalized()
    return Matrix((x, y, x.cross(y))).transposed()


def resolver_pierna(rig, s, T, rot_pie, rodilla):
    """Coloca thigh/shin/foot de un lado en el fotograma actual (la pelvis ya está evaluada): tobillo en T,
    rodilla en el plano que contiene 'rodilla' y bota con la orientación 'rot_pie' (espacio del armature).
    Devuelve los cuaterniones locales y lo que faltó para llegar (0 si alcanza)."""
    r = REST[s]
    j = r["j"]
    hb = rig.pose.bones["hips"]
    Dh = hb.matrix @ rig.data.bones["hips"].matrix_local.inverted()
    H = Dh @ j["hip"]
    l1, l2 = r["l1"], r["l2"]
    D = T - H
    d0 = D.length
    d = min(max(d0, abs(l1 - l2) + 1e-3), (l1 + l2) * 0.9995)
    u = D.normalized()
    v = rodilla - u * rodilla.dot(u)
    v.normalize()
    a = (l1 * l1 - l2 * l2 + d * d) / (2 * d)
    h = math.sqrt(max(l1 * l1 - a * a, 0.0))
    K = H + u * a + v * h
    T2 = H + u * d
    # muslo: el eje de reposo pasa a cadera->rodilla y la referencia de rodilla de la malla pasa a 'v'
    r1 = j["knee"] - j["hip"]
    Dt = _marco(K - H, v) @ _marco(r1, r["rodilla"]).transposed()
    # espinilla: del eje que traería el muslo al eje rodilla->tobillo
    r2 = Dt @ (j["ankle"] - j["knee"])
    Ds = r2.rotation_difference(T2 - K).to_matrix() @ Dt
    Df = rot_pie @ r["Rf"].inverted()
    Dh3 = Dh.to_3x3().normalized()
    qt = (r["Rt"].inverted() @ Dh3.inverted() @ Dt @ r["Rt"]).to_quaternion()
    qs = (r["Rs"].inverted() @ Dt.inverted() @ Ds @ r["Rs"]).to_quaternion()
    qf = (r["Rf"].inverted() @ Ds.inverted() @ Df @ r["Rf"]).to_quaternion()
    return {"thigh": qt, "shin": qs, "foot": qf}, max(0.0, d0 - d), K


def _key_piernas(rig, frame, sol, prev):
    for s in ("L", "R"):
        for n, q in sol[s].items():
            pb = rig.pose.bones[f"{n}.{s}"]
            k = f"{n}.{s}"
            q = q.normalized()
            if k in prev and prev[k].dot(q) < 0:
                q.negate()
            prev[k] = q.copy()
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=frame)


def longitudes(s):
    j = PIERNAS[s]
    return (Vector(j["knee"]) - Vector(j["hip"])).length + (Vector(j["ankle"]) - Vector(j["knee"])).length


def ciclo_locomocion(rig, nombre, informe):
    """Crea la acción 'nombre' (walk/run): pelvis, tronco, brazos y cola por rotaciones (como
    chicken_rig.py) y piernas por IK analítica sobre las trayectorias de los pies."""
    c = CICLOS[nombre]
    N = c["frames"]
    A = HeroAnimator(rig)
    act = A.new_action(nombre)
    pies = {s: Pie(rig, s, c["punta_fuera"]) for s in ("L", "R")}
    largo = {s: longitudes(s) for s in ("L", "R")}
    corr = 0.0
    # pelvis: dos subidas por ciclo; se baja lo necesario para que ninguna pierna se estire de más
    for intento in range(6):
        filas = []
        peor = 0.0
        for i in range(N + 1):
            ph = i / N
            fase = {"L": ph % 1.0, "R": (ph + 0.5) % 1.0}
            sp = (ph * 2.0) % 1.0
            # paso (dos por ciclo): lo más bajo justo tras el apoyo, lo más alto en 'sube_en'
            dz = c["pelvis"] + corr - c["bob"] * 0.5 + c["bob"] * 0.5 * (1 - math.cos(2 * math.pi * (sp - c["sube_en"] + 0.5)))
            yaw = -math.radians(c["giro_pelvis"]) * math.cos(2 * math.pi * ph)
            # desplazamiento lateral hacia el pie de apoyo (izquierdo = +x en la primera mitad)
            dx = c["ladeo"] * math.sin(2 * math.pi * (ph + 0.1))
            R = Matrix.Rotation(yaw, 3, 'Z')
            hips_rest = Vector((0, 0, 0.80))
            fila = {"f": i + 1, "dz": dz, "yaw": yaw, "dx": dx}
            for s in ("L", "R"):
                tob, rot, suela, apoyo = trayectoria_pie(pies[s], c, fase[s])
                hip = hips_rest + Vector((dx, 0, dz)) + R @ (Vector(PIERNAS[s]["hip"]) - hips_rest)
                dd = (tob - hip).length / largo[s]
                peor = max(peor, dd)
                fila[s] = dict(tob=tob, rot=rot, apoyo=apoyo)
            filas.append(fila)
        if peor <= ALCANCE:
            break
        corr -= (peor - ALCANCE) * max(largo.values()) * 1.2
    print(f"[{nombre}] pelvis media {c['pelvis'] + corr:+.3f} m, alcance máx {peor:.3f}")
    for r in filas:
        i = r["f"] - 1
        ph = i / N
        w = math.cos(2 * math.pi * ph)            # +1: pierna izquierda delante -> brazo izquierdo atrás
        yaw_deg = math.degrees(r["yaw"])
        if nombre == "walk":
            brazo = 20.0
            pose = {
                "hips": (0, 0, yaw_deg),
                "spine": (c["inclina"], 0, -yaw_deg * 0.6), "chest": (0, 0, -yaw_deg * 0.7),
                "head": (-c["inclina"] + 1.5 * math.sin(4 * math.pi * ph), 0, yaw_deg * 0.3),
                "upper_arm.L": (brazo * w + 2, -7, 0), "forearm.L": (-14 - 10 * max(0.0, -w), 0, 0),
                "upper_arm.R": (-brazo * w + 2, 7, 0), "forearm.R": (-14 - 10 * max(0.0, w), 0, 0),
                "crest": (-3 * math.sin(4 * math.pi * ph), 0, 0),
            }
            pose.update(RIG.tail_wag(8 * math.sin(2 * math.pi * ph)))
        else:
            brazo = 42.0
            pose = {
                "hips": (6, 0, yaw_deg),
                "spine": (c["inclina"], 0, -yaw_deg * 0.7), "chest": (3, 0, -yaw_deg * 0.8),
                "head": (-c["inclina"] - 6 + 3 * math.sin(4 * math.pi * ph), 0, yaw_deg * 0.3),
                "upper_arm.L": (brazo * w, -10, 0), "forearm.L": (-78 - 14 * max(0.0, -w), 0, 0),
                "upper_arm.R": (-brazo * w, 10, 0), "forearm.R": (-78 - 14 * max(0.0, w), 0, 0),
                "hand.L": (-8, 0, 0), "hand.R": (-8, 0, 0),
                "crest": (12 + 4 * math.sin(4 * math.pi * ph), 0, 0),
            }
            pose.update(RIG.tail_wag(14 * math.sin(2 * math.pi * ph)))
            pose["band_tail"] = (-24 - 6 * math.sin(4 * math.pi * ph), 0, -8 * math.sin(2 * math.pi * ph))
        A.key(r["f"], pose, {"hips": (r["dx"], 0, r["dz"])})
    # piernas: con la pelvis ya animada, IK fotograma a fotograma
    scn = bpy.context.scene
    prev = {}
    falta = 0.0
    for r in filas:
        scn.frame_set(r["f"])
        sol = {}
        for s in ("L", "R"):
            sol[s], f, _ = resolver_pierna(rig, s, r[s]["tob"], r[s]["rot"], pies[s].fwd)
            falta = max(falta, f)
        _key_piernas(rig, r["f"], sol, prev)
    print(f"[{nombre}] distancia máxima que no alcanza el tobillo: {falta * 1000:.1f} mm")
    informe[nombre] = _medir(rig, act, N, c)
    informe[nombre]["no_alcanza_mm"] = round(falta * 1000, 1)
    return act


def idle_plantado(rig, informe):
    """«idle» de chicken_rig.py (respiración, brazos, cola) con las botas fijas en su sitio de reposo."""
    act = bpy.data.actions["idle"]
    rig.animation_data.action = act
    f0, f1 = (int(x) for x in act.frame_range)
    scn = bpy.context.scene
    prev = {}
    # los muslos de idle traían un cierre de 7° que movía las botas: se sustituyen por IK
    for s in ("L", "R"):
        for n in ("thigh", "shin", "foot"):
            dp = f'pose.bones["{n}.{s}"].rotation_quaternion'
            for fc in [fc for fc in _fcurves(act) if fc.data_path == dp]:
                _fcurves_remove(act, fc)
    for f in range(f0, f1 + 1):
        scn.frame_set(f)
        sol = {s: resolver_pierna(rig, s, REST[s]["j"]["ankle"], REST[s]["Rf"], REST[s]["rodilla"])[0] for s in ("L", "R")}
        _key_piernas(rig, f, sol, prev)
    informe["idle"] = _medir(rig, act, f1 - f0, None)


# Los ciclos se exportaban desde el fotograma 1: en el GLB la primera clave queda a 1/30 s y Godot mantiene
# esa pose desde 0, así que cada vuelta del bucle repetía un fotograma (un pequeño tirón por ciclo).
LOOPS = ("idle", "battle_idle", "walk", "run", "special_charge")


def empezar_en_cero(nombres):
    for n in nombres:
        act = bpy.data.actions[n]
        for fc in _fcurves(act):
            for k in fc.keyframe_points:
                k.co.x -= 1.0
                k.handle_left.x -= 1.0
                k.handle_right.x -= 1.0
            fc.update()
        if act.use_frame_range:
            act.frame_range = (act.frame_range[0] - 1, act.frame_range[1] - 1)


def _fcurves(act):
    if hasattr(act, "fcurves"):
        return list(act.fcurves)
    out = []
    for layer in act.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                out += list(bag.fcurves)
    return out


def _fcurves_remove(act, fc):
    if hasattr(act, "fcurves"):
        act.fcurves.remove(fc)
        return
    for layer in act.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                if fc in list(bag.fcurves):
                    bag.fcurves.remove(fc)
                    return


def _medir(rig, act, N, c):
    """Medidas del ciclo terminado: altura de la suela, fotogramas sin apoyo y deslizamiento en apoyo."""
    scn = bpy.context.scene
    rig.animation_data.action = act
    f0 = int(act.frame_range[0])
    out = {"frames": N}
    prev = {}
    desliz, n_ap, alto_min, sin_suelo = 0.0, 0, 9.0, 0
    for i in range(N + 1):
        scn.frame_set(f0 + i)
        alg = False
        for s in ("L", "R"):
            pb = rig.pose.bones[f"foot.{s}"]
            M = rig.matrix_world @ pb.matrix @ rig.data.bones[f"foot.{s}"].matrix_local.inverted()
            su = SUELA[s]
            heel = Vector((su["heel"][0], su["heel"][1], 0.0))
            toe = Vector((su["toe"][0], su["toe"][1], 0.0))
            pts = [M @ p for p in (heel, heel.lerp(toe, 0.7), toe)]
            alto_min = min(alto_min, min(p.z for p in pts))
            ap = [p.z < 0.015 for p in pts]
            if any(ap):
                alg = True
                # deslizamiento: puntos de la suela apoyados en este fotograma y en el anterior
                if c and s in prev:
                    v_suelo = c["zancada"] / N
                    ds = [math.hypot(p.x - q.x, (p.y - q.y) - v_suelo) for p, q, a, b in zip(pts, prev[s][0], ap, prev[s][1]) if a and b]
                    if ds:
                        desliz += sum(ds) / len(ds) / v_suelo
                        n_ap += 1
            prev[s] = (pts, ap)
        if not alg:
            sin_suelo += 1
    out.update(suela_min=round(alto_min, 4), pct_sin_pie_en_suelo=round(100.0 * sin_suelo / (N + 1), 1),
               desliz_relativo=round(desliz / max(n_ap, 1), 3))
    print(f"[medida] {act.name}: {out}")
    return out


def exportar(rig, body):
    bpy.ops.object.select_all(action='DESELECT')
    rig.select_set(True)
    body.select_set(True)
    bpy.context.view_layer.objects.active = rig
    rig.animation_data.action = None
    for pb in rig.pose.bones:
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
    bpy.ops.export_scene.gltf(
        filepath=OUT_GLB, export_format='GLB', use_selection=True,
        export_animations=True, export_animation_mode='ACTIONS',
        export_force_sampling=True, export_skins=True, export_yup=True,
        export_apply=True, export_materials='EXPORT', export_def_bones=False,
        export_optimize_animation_size=True, export_tangents=True, export_image_format='AUTO',
    )


if __name__ == "__main__":
    rig, body = _rig_body()
    recolocar_piernas(rig)
    recalcular_pesos_bajos(rig, body)
    _reposo(rig)
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)
    RIG.Animator = HeroAnimator
    RIG.build_animations(rig, "hero")
    for n in ("walk", "run"):
        bpy.data.actions.remove(bpy.data.actions[n])
    informe = {}
    idle_plantado(rig, informe)
    for n in ("walk", "run"):
        ciclo_locomocion(rig, n, informe)
    for a in bpy.data.actions:
        a.use_fake_user = True
    empezar_en_cero(LOOPS)
    rig.animation_data.action = None
    if os.environ.get("INFORME"):
        json.dump(informe, open(os.environ["INFORME"], "w"), indent=1)
    if os.environ.get("GUARDAR"):
        bpy.ops.wm.save_as_mainfile(filepath=os.environ["GUARDAR"], copy=True)
    if not os.environ.get("SIN_EXPORTAR"):
        exportar(rig, body)
        bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("[OK] locomoción del héroe:", json.dumps(informe))
