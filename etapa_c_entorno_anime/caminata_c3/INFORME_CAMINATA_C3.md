# Corrección de la caminata del personaje en C3

Proyecto RPG Godot 4.7 · rama de la C3 (`etapa-b-cel-shading-anime`) · validado con Godot 4.7.2 · 2026-10-31

Sin etapa C4, sin escenas ni personajes nuevos, sin tocar el entorno, la cámara, el combate, los diálogos, el
HUD ni los controles. **No está integrado en la versión principal**: queda pendiente de tu revisión.

**Para revisar primero:** los videos del resultado en [`videos/`](videos/) (60 FPS, cámaras fijas que solo
acompañan al personaje sin girar) y la lámina
[`comparaciones/articulaciones_antes_despues.jpg`](comparaciones/articulaciones_antes_despues.jpg).

---

## 1. Causa exacta del movimiento antinatural

Hay una causa principal y tres que la agravaban. Ninguna estaba en la cámara ni en el entorno.

### Causa principal: el esqueleto no correspondía a las piernas del modelo

El Pollo Amarillo es el modelo de Meshy («Crimson Talon Warrior») con un esqueleto que se le puso en la v10.
Ese esqueleto se colocó con **articulaciones simétricas** (cadera, rodilla y tobillo iguales a los dos lados),
pero el modelo está de pie en una **guardia abierta y asimétrica**:

| Medida sobre la malla (cortes horizontales y suela) | Pierna izquierda | Pierna derecha |
|---|---|---|
| Bota adelantada | 18 cm por delante | — |
| Giro de la punta hacia fuera | 25° | 43° |
| Tobillo del esqueleto respecto al centro real de la bota | 14 cm fuera (borde interior y trasero) | 7 cm fuera |
| Rodilla del esqueleto respecto al centro de la pernera | 9 cm fuera | 6 cm fuera |

Vista de lado: con el esqueleto anterior las dos piernas compartían la misma línea de articulaciones, y el
tobillo izquierdo quedaba detrás de la bota adelantada, dentro de la otra bota. Con eso:

* la pierna se doblaba por donde no hay rodilla (pernera «quebrada» o torcida);
* la bota giraba alrededor de un punto fuera del tobillo (pies que «barren» de lado);
* las botas conservaban al caminar el giro de 25° y 43° de la guardia: parecía caminar de lado.

### Causas que lo agravaban

1. **Animaciones sin contacto con el suelo.** `walk` y `run` eran cuatro poses de rotación directa,
   hechas para el pollo de piernas cortas de la v8 y ajustadas en la v10 cerrando los muslos 9°. Sin
   ningún cálculo de apoyo: caminando, en el 27 % del ciclo **ningún pie tocaba el suelo** y el pie
   apoyado se hundía hasta 7 cm; corriendo, el 81 % del tiempo en el aire.
2. **Velocidad que no correspondía a la zancada.** Caminar a 2,3 m/s con unas piernas de 0,71 m (altura de
   cadera) es un trote (número de Froude 0,76; la caminata humana deja de ser posible por encima de ~0,5).
   La animación cubría ~1,6 m/s, así que **el pie apoyado patinaba al 96 % de la velocidad del cuerpo**.
   El factor fijo de 1,45 de la v11 solo aceleraba las piernas.
3. **Un fotograma repetido en cada vuelta.** Los ciclos se exportaban desde el fotograma 1: en el GLB la
   primera clave quedaba a 1/30 s y Godot mantenía esa pose desde 0, un pequeño tirón en cada ciclo.
4. **La inclinación del cuerpo hundía las botas.** El controlador inclinaba el modelo entero hasta 9°
   al acelerar alrededor del punto de los pies: la puntera entraba 5 cm en el suelo.

Descartado tras inspección: no hay AnimationTree ni BlendSpace (se usa `AnimationPlayer` directamente desde
`ChickenVisual`), no hay root motion (solo la pelvis sube y baja), la orientación del modelo y del
esqueleto es correcta (mira a +Z en Godot, a −Y en Blender), no hay retargeting (rig y animaciones salen
del mismo script de Blender), las rodillas nunca se invertían, y no existía IK de pies.

## 2. Archivos y escenas modificados

| Archivo | Cambio |
|---|---|
| `blender/scripts/locomocion_heroe.py` | **Nuevo.** Corrige el rig de las piernas y genera idle/walk/run con pies plantados |
| `blender/characters/pollo_amarillo.blend` | Regenerado con ese script |
| `assets/characters/pollo_amarillo.glb` | Regenerado (misma malla, texturas y nombres de huesos y animaciones) |
| `scripts/selva/cinematic_player.gd` | Velocidad de caminar, sincronía animación/zancada, cambio caminar/correr, pisadas, inclinación |
| `scripts/player/chicken_visual.gd` | Dos funciones añadidas (`play_ciclo`, `fase_ciclo`); `play()` no cambia |
| `tests/locomocion_tests.gd` | **Nuevo.** 29 pruebas de pisada |
| `tests/tools/medidor_pisada.gd`, `tests/tools/sonda_locomocion.gd`, `tests/tools/SondaLocomocion.tscn` | **Nuevos.** Medidor y sonda de las pruebas visuales A–D |
| `tests/e2e_director.gd` | Ejecuta las pruebas de locomoción (modos `all`, `unit`, `locomocion`) |
| `tests/anime_tests.gd` | Actualiza la huella MD5 del GLB del Pollo Amarillo (cambio intencionado, la anterior queda anotada) |
| `tests/entorno_c3_tests.gd` | La prueba de velocidad del recorrido lee `walk_speed` en vez de un rango fijo de 2,0–2,6 m/s |
| `CHANGELOG.md` | Entrada de esta corrección |

Ninguna escena (`.tscn`) del juego ni de la C3 cambia. Respaldo de los archivos anteriores:
`selva/respaldo/caminata_c3/` en los archivos del proyecto (GLB, .blend, `cinematic_player.gd`,
`chicken_visual.gd`).

## 3. Cambios en el rig, las animaciones y el controlador

### Rig (solo piernas)
* Cadera, rodilla, tobillo y punta de cada pierna recolocadas **en el eje de su pierna**, medido sobre la
  malla. Las dos piernas ya no son simétricas porque el modelo no lo es. Los nombres de los huesos no
  cambian.
* Pesos recalculados **solo por debajo de 0,92 m** (fundido desde 0,80 m) con el método de calor de Blender.
  Tronco, brazos, cabeza, cresta y bandana conservan exactamente sus pesos.
* Malla, texturas, proporciones y apariencia: sin cambios.

### Animaciones
* `walk` (24 fotogramas, zancada 1,10 m) y `run` (16 fotogramas, zancada 2,00 m) se **calculan desde la
  trayectoria de los pies**: apoyo de talón, pie plano, despegue sobre la puntera, altura de paso y empalme
  sin tirones. Las piernas se resuelven con **IK analítica de dos huesos**, con la rodilla hacia la punta de
  la bota, y se guardan como claves de rotación normales. El GLB no lleva IK en tiempo real.
* Las botas apuntan hacia delante al caminar (8° hacia fuera) y al correr (6°): toda la pierna rota
  hacia dentro desde la cadera, como una persona que sale de una guardia.
* Pelvis: baja tras el apoyo y sube en el apoyo medio, gira con el paso y se desplaza hacia el pie de
  apoyo. Tronco, hombros y cabeza contrarrotan. Los brazos van en oposición a las piernas. Cola y bandana
  acompañan.
* `run` tiene fase de vuelo real (35 % del ciclo), inclinación del tronco, brazos doblados a 80–90° y
  recogida del talón detrás del cuerpo.
* `idle`: los mismos movimientos de siempre (respiración, brazos, cola), pero con las botas fijas en su sitio
  de reposo. Antes se hundían 2,5 cm.
* Los ciclos empiezan en el fotograma 0: se acaba el tirón de cada vuelta.
* El resto de acciones (combate, victoria, derrota…) se regeneran con **las mismas definiciones** de
  `chicken_rig.py`. Era necesario porque cambió la pose de reposo de las piernas. Su intención es la misma.

### Controlador (`cinematic_player.gd`)
* `walk_speed` pasa de 2,3 a **1,7 m/s**: un paso ligero natural para estas piernas. `run_speed` sigue en
  4,4 m/s.
* La animación se reproduce a la velocidad que hace coincidir zancada y desplazamiento
  (`walk_stride`/`run_stride`). Esto sustituye los factores fijos 1,45 y 1,25.
* Caminar ↔ correr cambia a 2,75 m/s con histéresis, **conservando la fase**. Los dos ciclos apoyan el pie
  izquierdo en la fase 0, así que la mezcla no cruza las piernas.
* Las pisadas (señal `step`) salen del apoyo real de cada pie.
* La inclinación al acelerar y en las curvas se reduce a 3–4°. La inclinación de la marcha ya está en las
  animaciones.
* No cambian el giro, la aceleración, el frenado, las colisiones, el escalón, la zona caminable, el modo de
  equilibrio en ramas ni la relación con la cámara.

## 4. Comparación antes / después

Medido sobre el esqueleto animado en Godot 4.7.2, a 60 FPS, con las mismas entradas del jugador. Se midieron
la suela de cada bota (talón, metatarso y puntera) con un rayo contra el suelo, el deslizamiento de los
puntos apoyados, el apoyo, la dirección de la rodilla y la orientación de la bota.

| Tramo | Velocidad (m/s) | Pie apoyado que patina (% de la velocidad) | Sin ningún pie en el suelo | Suela más hundida | Pie más bajo flotando (máx.) | Desvío medio de la bota apoyada |
|---|---|---|---|---|---|---|
| Caminata (A) | 2.24 → **1.67** | 96 % → **14 %** | 27 % → **0 %** | -6.6 cm → **-3.6 cm** | 5.3 cm → **0.1 cm** | 23° → **9°** |
| Carrera (B) | 4.40 → **4.40** | 60 % → **2 %** | 81 % → **37 %** | -6.0 cm → **-0.5 cm** | 13.2 cm → **9.7 cm** | 18° → **6°** |
| Quieto → caminar (C) | 1.91 → **1.49** | 94 % → **37 %** | 20 % → **0 %** | -6.5 cm → **-4.3 cm** | 5.2 cm → **0.1 cm** | 25° → **15°** |
| Caminar → correr (C) | 4.08 → **3.86** | 72 % → **12 %** | 55 % → **27 %** | -7.1 cm → **-3.4 cm** | 13.0 cm → **8.9 cm** | 18° → **7°** |
| Correr → caminar (C) | 2.53 → **2.08** | 99 % → **13 %** | 35 % → **8 %** | -6.7 cm → **-1.7 cm** | 13.3 cm → **8.2 cm** | 21° → **8°** |
| Caminar → detenerse (C) | 0.23 → **0.12** | 187 % → **270 %** | 0 % → **0 %** | -7.0 cm → **-2.2 cm** | 0.0 cm → **0.1 cm** | 26° → **28°** |
| Camino C3 caminando (D) | 2.19 → **1.64** | 96 % → **13 %** | 25 % → **0 %** | -7.3 cm → **-4.1 cm** | 6.2 cm → **1.0 cm** | 23° → **9°** |
| Camino C3 corriendo (D) | 4.05 → **4.03** | 65 % → **7 %** | 72 % → **30 %** | -6.6 cm → **-4.0 cm** | 13.7 cm → **9.7 cm** | 19° → **7°** |

En la carrera, «pie más bajo flotando» es la fase de vuelo, que es correcta en una carrera. En «caminar →
detenerse» el porcentaje de deslizamiento se divide entre una velocidad casi nula. Lo que se ve son las botas
volviendo a la postura de guardia durante la mezcla de 0,3 s (ver pendientes).

Láminas:
* `comparaciones/articulaciones_antes_despues.jpg`: articulaciones del esqueleto sobre la malla en
  transparencia.
* `comparaciones/caminar_blender_antes_despues.jpg`: ciclo de caminata, de frente, de espaldas y de lado.
* `comparaciones/correr_blender_despues.jpg`: ciclo de carrera nuevo.
* `comparaciones/fotogramas_A.jpg` … `fotogramas_D.jpg`: fotogramas de los videos del resultado.

## 5. Resultados de las pruebas visuales

Todas las grabaciones usan el personaje original (`PlayerCinematic.tscn` sin cambios de escena) a 60 FPS,
con Forward+.

| Prueba | Contenido | Video |
|---|---|---|
| A · Caminata | Suelo plano cuadriculado; vistas frontal, trasera y lateral; quieto → caminar 6 s → detenerse | [`videos/A_caminata.mp4`](videos/A_caminata.mp4) |
| B · Carrera | Vistas frontal y lateral; arranque, carrera 4,5 s, detenerse | [`videos/B_carrera.mp4`](videos/B_carrera.mp4) |
| C · Transiciones | Lateral y frontal: quieto → caminar → correr → caminar → detenerse | [`videos/C_transiciones.mp4`](videos/C_transiciones.mp4) |
| D · Entorno C3 | Camino principal caminando; cámara al hombro del juego + cámara baja a los pies | [`videos/D_camino_c3.mp4`](videos/D_camino_c3.mp4) |

Las cámaras de A–C son fijas: solo acompañan al personaje en línea recta, sin girar. La cuadrícula de 0,5 m
deja ver si un pie apoyado patina. Como pediste, solo se entregan los videos del resultado. El «antes» queda
en las medidas de la tabla del punto 4.

El video D dura 9 s y solo muestra el tramo caminando: la selva se renderiza por CPU (unas 2 h por video) y
un reinicio del entorno cortó la grabación. El tramo corriendo por el camino de C3 sí está medido (tabla del
punto 4).

Lo que se ve en los videos:
* las piernas se alternan coordinadas, cada bota apoya de talón, rueda y despega de puntera;
* las rodillas se doblan hacia delante, sobre la punta de la bota, y las botas miran hacia donde se camina;
* el pie apoyado queda quieto contra la cuadrícula;
* la pelvis sube y baja con el paso, el tronco contrarrota y los brazos van en oposición;
* la carrera tiene fase de vuelo y no patina;
* los cambios de caminar a correr no cruzan las piernas.

En el camino de C3 (D), las pequeñas irregularidades del terreno hunden la suela como máximo 4 cm en el 1,3 %
de los fotogramas, y el pie más bajo nunca flota más de 1 cm.

## 6. Resultados de las pruebas automatizadas

* Suite completa con Godot 4.7.2 (`--headless --mode=all`): **360 correctas, 0 fallidas**. Son las 331
  anteriores más 29 nuevas de locomoción. Resultado en `pruebas/resultado_mode_all_472.txt`.
* Pruebas nuevas (`--mode=locomocion`):
  * rodillas y tobillos del esqueleto en el eje de la pierna;
  * proporción de muslo y espinilla;
  * ciclos sin fotograma repetido;
  * velocidad de caminar y correr;
  * deslizamiento del pie apoyado por debajo del 12 %;
  * siempre un pie en el suelo al caminar y fase de vuelo al correr;
  * suelas sin hundirse;
  * rodillas al frente y flexión menor de 100° al caminar;
  * botas hacia delante;
  * transiciones sin saltos de pose;
  * reposo con las botas plantadas.
* Dos pruebas anteriores se ajustaron porque el cambio es intencionado: la huella MD5 del GLB y el rango fijo
  de la velocidad de caminar de la C3.
* Medidas completas (JSON) de antes y después en `pruebas/medidas/`.

Las pruebas automáticas no bastan para dar por buena la animación. La aprobación depende de que tú veas los
videos.

## 7. Problemas pendientes

1. **Detenerse y arrancar.** Al pasar entre la guardia del reposo (pies abiertos y adelantado el izquierdo) y
   la línea de marcha, la mezcla de 0,3 s mueve las botas a su sitio y la suela baja hasta ~4 cm durante un
   instante. Se arreglaría con animaciones cortas de arranque y parada, o con un ajuste de pies en tiempo
   real. Ninguna de las dos se hizo, para no meter sistemas nuevos sin tu visto bueno.
2. **Terreno irregular.** No hay IK de pies en tiempo real. En el camino de C3 no hace falta (−4 cm como
   máximo, en el 1,3 % de los fotogramas), pero en pendientes fuertes una bota podría hundirse o flotar
   unos centímetros.
3. **Caminar más lento.** Caminar a 1,7 m/s en vez de 2,3 m/s es parte de la corrección: a 2,3 m/s estas
   piernas solo pueden trotar o patinar. Si prefieres más velocidad al caminar, se puede subir hasta ~1,9 m/s
   con la misma animación (la cadencia sube con la velocidad), o hacer una «caminata rápida» propia.
4. **Pliegues de la pernera.** Las perneras anchas de Meshy se pliegan algo en la flexión máxima de la
   carrera. Es geometría del modelo, que no se ha tocado.
5. **Pollo Negro.** Es otro modelo con otro esqueleto y no se ha revisado.

## 8. Confirmación de alcance

* No se modificaron: el entorno C3 (escena, árboles, rocas, colisiones, shaders, iluminación, ciclo de
  horas), `DirectorCamaras` ni los planos de cámara, el combate y sus scripts, los diálogos, el HUD, los
  controles e `InputMap`, el menú, las opciones, el estilo anime, la C1, la C2, la Etapa B ni el v13.
* El personaje es el mismo: misma malla, mismas texturas, mismas proporciones.
* Las animaciones de combate se regeneraron con sus mismas definiciones por el cambio de reposo de las
  piernas. Las pruebas de combate y del recorrido completo del juego (e2e) pasan dentro de la suite.
* Nada se ha integrado en la versión principal.
