# CHANGELOG

## Etapa C anime, revisión C2: selva de prueba rehecha (2026-10-30)

Escena nueva y aislada `scenes/pruebas/PruebaEntornoAnimeC2.tscn`. La escena C1, la Etapa B, el juego y
el mundo no cambian. Validada con Godot 4.7.2.

- `scripts/anime/selva_c2.gd` (`SelvaC2`): árboles procedurales por especie (ceiba con raíces de
  tabla, árbol de copa redonda, árbol joven), con ramas reales y copas hechas de racimos de hojas;
  rocas facetadas con planos de corte y base hundida; suelo con relieve suave y camino; masa de selva
  lejana para cerrar el horizonte.
- `assets/materials/anime/anime_copa.gdshader`: racimos de hojas con corte alfa, normales de copa,
  viento y bandas. Atlas `assets/anime/selva_c2/racimo_hojas.png` (generado con `tools/c2/generar_racimos.py`).
- `assets/materials/anime/anime_suelo_selva.gdshader`: suelo por zonas con borde definido (camino,
  hojarasca, musgo, humedad, tres tonos de hierba), sin texturas ni manchas difuminadas.
- `scripts/anime/prueba_entorno_c2.gd`: bosque con especies según la distancia al camino, sotobosque
  en manchas, rocas en grupos, luz anime por hora (cielo, bruma, sol y luna), encuadres y capturas
  con comparación v13 en el mismo sitio.
- `tests/entorno_c2_tests.gd`: 20 pruebas nuevas.

## Etapa C anime: entorno selvático de prueba (2026-10-30)

Solo en una escena de prueba nueva. El juego, el mundo y la escena de la Etapa B no cambian; el estilo
v13 se ve igual que antes y sirve de comparación (Tab).

**Nuevo**
- `scenes/pruebas/PruebaEntornoAnime.tscn` + `scripts/anime/prueba_entorno.gd` (`PruebaEntorno`, hereda
  de `PruebaAnime`): suelo de selva, bosque de fondo (2 árboles fijos y 14 repartidos sin tapar el
  centro), masas de copa volumétricas, rocas estilizadas, cielo anime por hora y bruma de selva.
  Capturas: `-- --capturas=/ruta`. Medición: `-- --medir=120`.
- `scripts/anime/entorno_selva.gd` (`EntornoSelva`): suelo con parches de color por vértice, masas de
  copa y rocas procedurales (esferas deformadas con ruido, caras orientadas para cull_back).
- `assets/materials/anime/anime_terreno.gdshader`: suelo por bandas con color por vértice y variación
  de tono a dos escalas, sin texturas fotográficas.
- `tests/entorno_anime_tests.gd`: 10 pruebas (modo `anime`, incluidas en `all` y `unit`).

**Cambiado**
- `tests/e2e_director.gd`: ejecuta las pruebas del entorno.

## Etapa B anime: sistema de materiales cel shading y laboratorio (2026-10-30)

Prueba controlada sobre v13. El juego sigue igual por defecto (estilo «Pictórico (v13)»); el mundo no
cambia de materiales hasta la Etapa C y los personajes conservan malla, esqueleto, pesos y animaciones.

**Nuevo (carpetas propias)**
- `assets/materials/anime/anime_luz.gdshaderinc`: `light()` común. Bandas (2 o 3) con umbral y
  suavizado, color de sombra propio (no negro), intensidad de luz, sombras del sol endurecidas,
  brillo especular en mancha, luz de borde a contraluz y translucidez de hojas.
- `anime_personaje.gdshader` (personajes; `pintado` aplana el ruido de la textura con un mip alto),
  `anime_contorno.gdshader` (casco invertido en `next_pass`, grosor en píxeles que se adelgaza con la
  distancia, color de la textura oscurecido), `anime_entorno.gdshader` (madera, piedra, mimbre: color
  plano + detalle pintado + musgo en masa), `anime_follaje.gdshader` (normales esféricas, viento y
  doblado al paso del jugador) y `anime_contorno_post.gdshader` (líneas de pantalla por profundidad y
  normales, solo Forward+, sin líneas en cada hoja ni dobles en los personajes).
- `scripts/anime/estilo_anime.gd` (`EstiloAnime`): fábrica por familias, perfil de entorno y sol anime,
  conversión y restauración de personajes, contorno de pantalla.
- `scenes/pruebas/PruebaAnime.tscn` + `scripts/anime/prueba_anime.gd`: laboratorio con esferas, madera,
  rocas, follaje y los dos pollos. Botón «Laboratorio anime» en el menú principal. Teclas: Tab estilo,
  1-8 plano, H hora, L sol, O contornos, Esc menú. Capturas: `-- --capturas=/ruta --plan=completo`.
- `tests/anime_tests.gd` + laboratorio en `e2e_director.gd`: 29 pruebas (modo `--mode=anime`, incluidas
  en `all` y `unit`).

**Cambiado**
- `Ajustes`: `estilo` (Pictórico v13 de fábrica / Anime prueba) y `contornos`, guardados en ajustes.cfg.
- `OptionsPanel`: filas «Estilo visual» y «Contornos anime». `CinematicLook`: el filtro pictórico se
  oculta en el estilo anime. `MainMenu`: botón «Laboratorio anime».

## v13: misión maestra — habilidades por datos, cascadas del Cenote Azul y opciones de PC (2026-10-25)

Construida sobre v12 sin rehacer nada: mismas escenas, mismo combate, mismos personajes y controles.

**Combate (fase E)**
- Sistema de habilidades reutilizable. `HabilidadCinematica` (`scripts/combat/habilidad_cinematica.gd`,
  recursos `.tres` en `assets/data/habilidades/`) describe solo la presentación: título, elemento,
  colores, intensidad, animaciones, planos (vuelta, ojos, fotograma invertido), proyectil, cámara lenta,
  franjas, temblor, reacción del objetivo y sonidos. `CinematicaHabilidad` (`cinematica_habilidad.gd`)
  la reproduce por partes: `preludio()`, `lanzar()`, `impacto()`, `terminar()`. Sustituye a `super_pluma.gd`.
- Pluma Ígnea (héroe) y Garra Sombría (Pollo Negro) usan el mismo sistema. La Garra Sombría tiene
  ahora preludio con título, humo oscuro, primer plano y tres zarpazos; la ventana de parada se abre
  solo durante el lanzamiento, así que la parada funciona igual que antes.
- Coste, daño y turnos no cambian (siguen en `CombatantData`, `CombatRules` y `BattleController`).
  Pruebas nuevas: daño aplicado una sola vez, parada perfecta de la Garra Sombría, el turno vuelve.
- Escudo de defensa rehecho: solo brilla el borde con un patrón de escamas (antes era una burbuja
  blanca que tapaba al personaje en los planos cercanos).
- La reacción del objetivo depende de la habilidad: derribo (Pluma Ígnea) o retroceso (Garra Sombría).

**Selva (fases C y D)**
- `scripts/mundo/cascadas.gd`: cascada mayor de ~12 m que cae desde un risco de caliza al Cenote Azul,
  y un arroyo que baja por el terreno hasta una cascada menor. Shader propio `cascada.gdshader`
  (franjas de espuma que bajan, bordes deshilachados), bruma, gotas, espuma al pie y sonido 3D.
- Corregido un fallo visible desde v7: la pared del Cenote Azul era invisible por dentro (las caras
  miraban hacia fuera) y en su lugar se veía la niebla beige del fondo. Ahora se ve la roca húmeda con
  chorreones, algas cerca del agua y más oscuridad en lo hondo (`Roca_Cenote`). El agua refleja
  menos cielo y se ve turquesa desde el puente.
- La vegetación se aparta al paso del Pollo Amarillo y el sotobosque se mueve con el viento
  (`planta.gdshader`, parámetro global `jugador_pos`; también en las hojas bajas de `hojas_mundo`).
- `vida_ambiental.gd`: motas de luz doradas al atardecer, hojas que caen girando y luciérnagas que
  parpadean de noche, siempre alrededor del jugador.
- Revelación del mirador con franjas de cine, una pausa antes de la grúa y la música que crece.
- Punto de interés nuevo en el puente de piedra: «Contemplar la cascada» (cámara hacia la cascada y
  diálogo). Reacciones nuevas: el pozo salpica y los pollitos saltan al saludarlos.

**Interfaz y PC (fase F)**
- Autoload `Ajustes` + panel `OptionsPanel` en el menú principal y en la pausa: pantalla (ventana,
  pantalla completa, exclusiva), resolución, VSync, calidad Baja/Media/Alta/Ultra (sombras, SSAO, SSR,
  niebla volumétrica, SSIL, MSAA, escala de render con FSR, distancia de vegetación), cantidad de
  partículas y filtro pictórico. Se guarda en `user://ajustes.cfg`. En iPhone/Xogot solo aparecen las
  opciones que tienen sentido allí.
- Sonidos nuevos sintetizados: `cascada.wav`, `arroyo.wav`, `viento_hojas.wav` (`tools/generate_audio_agua.py`).

**Archivos nuevos**
`scripts/combat/habilidad_cinematica.gd`, `scripts/combat/cinematica_habilidad.gd`,
`assets/data/habilidades/pluma_ignea.tres`, `assets/data/habilidades/garra_sombria.tres`,
`scripts/core/ajustes.gd`, `scripts/ui/options_panel.gd`, `scripts/mundo/cascadas.gd`,
`scripts/mundo/vida_ambiental.gd`, `assets/materials/mundo/cascada.gdshader`,
`assets/materials/mundo/planta.gdshader`, `assets/audio/cascada.wav`, `assets/audio/arroyo.wav`,
`assets/audio/viento_hojas.wav`, `tools/generate_audio_agua.py`.

**Archivos modificados**
`project.godot` (autoload `Ajustes`, parámetro global de shader `jugador_pos`),
`assets/data/pollo_amarillo.tres` y `pollo_negro.tres` (campo `habilidad`; las estadísticas no cambian),
`scripts/combat/combat_scene.gd`, `combat_vfx.gd`, `combatant_data.gd`, `scripts/core/audio_manager.gd`
(`fade_music`), `cinematic_look.gd`, `scripts/dialogue/dialogue_data.gd`, `scripts/mundo/materiales_mundo.gd`,
`mundo3d.gd`, `mundo_construccion.gd`, `scripts/ui/main_menu.gd`, `pause_menu.gd`,
`assets/materials/mundo/agua_cenote.gdshader`, `hojas_mundo.gdshader`, `mundo_pbr.gdshader`,
`terreno.gdshader`, `tests/e2e_director.gd`, `test_runner.gd`, `unit_tests.gd`, `tests/tools/sonda_super.gd`,
`vista_mundo.gd`, `README.md`, `TEST_REPORT.md`, `licenses/ATTRIBUTIONS.md`, `screenshots/`.

**Retirado**: `scripts/combat/super_pluma.gd` (su contenido pasó a `cinematica_habilidad.gd`; la
versión anterior sigue en el ZIP de v12).

## v12: súper ataque «Pluma Ígnea» con cinemática de anime (2026-10-24)

Inspirado en el ritmo de los súper ataques de los juegos de lucha de anime que mandó Orlando, con
diseño y recursos propios (nada de Dragon Ball).
- `scripts/combat/super_pluma.gd`: al usar PODER la cámara de combate se sustituye por una cinemática
  de ~6 s con 9 planos: activación en contrapicado con destello blanco, franjas de cine y el título
  entrando de lado; aura y columna de fuego, ondas en el suelo y piedras que se levantan; vuelta de
  cámara alta; primer plano de los ojos en una franja estrecha con líneas de concentración; fotograma
  de impacto en blanco y negro invertido; lanzamiento desde la espalda de una pluma de fuego gigante
  con líneas de velocidad; plano lateral; corte al rival con cámara lenta (×0,22) justo antes del golpe;
  destello, segundo fotograma invertido, explosión con columna de fuego, anillos y temblor fuerte.
- El HUD se oculta durante la cinemática y vuelve al terminar; la velocidad del juego se restaura.
- `combat_stage.gd`: `set_custom()` para encuadres libres. `combat_vfx.gd`: `fire_feather(..., size)`.
- Pruebas nuevas del súper ataque; herramienta `tests/tools/SondaSuper.tscn` para grabarlo en vídeo
  (`--write-movie`).

## v11: caminar del nuevo Pollo Amarillo y cámara que ya no gira sola (2026-10-24)

Fallos del video de Orlando (iPhone, rama madre): el pollo caminaba muy mal y la cámara daba vueltas.
- Cámara: cuando todo detrás estaba tapado, el giro automático se recalculaba en cada fotograma y no
  paraba aunque soltaras el joystick. Ahora gira solo mientras caminas, hacia un ángulo fijo, con pausa
  entre giros, y parado como mucho una vez. Prueba nueva «Cámara quieta con el joystick suelto»: con la
  versión v10 la cámara giraba 1,64 rad (94°) en 3 s parado en la rama; ahora 0.
- Cámara: al salir del nido ya no se mete dentro de su cáscara (el nido no tiene colisión de cámara).
- Caminar y correr: las animaciones eran de un pollo de piernas cortas; en el modelo nuevo, con las
  piernas abiertas, parecía ir a horcajadas. Ahora los muslos se cierran, los pies van planos y rectos y
  la zancada es más larga (`build_hero_meshy.py`, `HeroAnimator`). Los pasos van más rápidos para seguir
  la velocidad (`walk_anim_rate` 1,45 y `run_anim_rate` 1,25 en `cinematic_player.gd`).
- Herramienta nueva `tests/tools/SondaCaminar.tscn` (capturas caminando y corriendo por la rama).
- A partir de esta versión se entrega solo el ZIP del proyecto (el .exe, cuando se pida).

## v10: nuevo Pollo Amarillo desde el modelo de Meshy (2026-10-24)

- El protagonista es ahora el modelo «Crimson Talon Warrior» que mandó Orlando, con su aspecto original:
  cresta y bandana rojas, chaqueta de cuero corta, pantalón rojo, cadena, guantes, botas y cola de plumas.
- Reducido de ~2 M a ~110 k triángulos; texturas originales de Meshy (color, metal/rugosidad, normales 2K).
- Mismo esqueleto y mismas 11 animaciones; articulaciones medidas sobre el nuevo cuerpo. Los pesos se
  corrigieron para que el cuello de la chaqueta y las puntas de la bandana no se estiren con los brazos.
- Retrato del HUD y del diálogo regenerado.
- Nuevo script `blender/scripts/build_hero_meshy.py`. El Pollo Amarillo v8 sigue en `build_characters_v2.py`.

## v9: cámara al hombro y combate con cartas (2026-10-24)

- Exploración: la cámara deja de ser por zonas y lejana. Ahora va en tercera persona sobre el hombro
  derecho del Pollo Amarillo (~3,2 m), le sigue y se coloca detrás al caminar. Se gira con Q / R, J / L,
  I / K, el ratón (arrastrar) o el stick derecho. Esquiva troncos y paredes y no se sale del nido.
- Combate: fuera de tu turno no aparece ningún botón. Cuando te toca, la cámara se acerca al hombro del
  héroe y se reparte una mano de 4 cartas en abanico (Ataque, Defensa, Parada, Poder). Se eligen con
  ← → y Enter, con 1-4 o con clic, y la elegida sube. Diseño propio, sin recursos de Baten Kaitos.
- La narración del combate se estrecha a la izquierda mientras están las cartas.
- Pruebas: nuevas comprobaciones de cámara al hombro, giro manual y aparición/ocultación de la mano.
- Herramienta nueva `tests/tools/SondaCombate.tscn` (capturas del turno con cartas).

## v8: personajes remodelados en Blender (2026-10-24)

- Pollo Amarillo y Pollo Negro rehechos desde las referencias (ilustración del Pollo Amarillo y hoja
  «Spike-Raven»). Ya no son piezas rígidas pegadas: el cuerpo es una sola malla orgánica con piel por
  pesos suaves, y la ropa son cáscaras sobre ese cuerpo.
- Pollo Amarillo: cuerpo atlético con abdominales, cabeza con párpados de ceño, ojos pintados, pico de
  pato, orejas puntiagudas, pelo rojo en púas, bandana con nudo y colas, chaqueta corta de cuero con
  cremalleras y tachas, pantalón rojo holgado con pliegues, cinturón y cadena, guantes sin dedos con
  tachas, botas con cordones y suela gruesa, cola de plumas.
- Pollo Negro: cabeza roja con arrugas y ceño, ojos amarillos, pico ganchudo, cresta mohicana en
  estallido, plumón negro en cuello, pecho, puños y espinillas, chaqueta motera con solapas, tachas y
  parches de calavera, pantalón cargo con bolsillos y correas, dos cadenas, guantes negros con puño rojo
  y garras rojas, botas grandes.
- Texturas horneadas 4K por personaje (color con oclusión, rugosidad y normales) en un solo material,
  más metal y ojos aparte. ~98 000 triángulos (Amarillo) y ~115 000 (Negro); Godot genera LOD.
- Mismos nombres de huesos y de las 11 animaciones: combate, mundo y menú funcionan sin cambios.
- Retratos del HUD y del diálogo regenerados.
- Nuevos scripts: `blender/scripts/sdf_lib.py`, `char_v2_lib.py`, `build_characters_v2.py`.

## v7.1: corrección del atasco en el puente de piedra (2026-10-23)

Fallo del video del iPhone: junto a la entrada norte del puente de piedra, el Pollo Amarillo se quedaba
atascado y ya no respondía.

Causas, reproducidas aquí con `tests/tools/SondaJugador.tscn`:
- El camino de llegada dejaba pisar el borde del cenote a un lado del puente. El personaje caía por el
  talud y quedaba encajado a 1,2 m por debajo, sin poder moverse.
- En ese mismo punto, un pliegue del terreno trababa la cápsula del personaje: `move_and_slide` no
  avanzaba nada aunque se empujara el joystick.

Correcciones:
- `mundo3d.gd`: la boca del cenote (radio 13,15 m) solo es caminable sobre el puente.
- `cinematic_player.gd`: si el personaje queda fuera de la zona caminable, cae más de 2,5 m o pasa más de
  1,5 s sin suelo, vuelve solo a un punto seguro de ~0,75 s antes. Si se traba en el suelo sin avanzar, se
  despega 5 cm y repite el paso.
- Prueba nueva en `--mode=mundo`: empujar hacia los huecos del borde y forzar una caída para comprobar
  que vuelve y puede seguir andando.
- Herramienta nueva `tests/tools/MapaCaminable.tscn`: mapa ASCII de las zonas caminables y de los huecos.

## v7: Aldea del Árbol Gigante en 3D en tiempo real (2026-10-23)

### Mundo 3D

- **Jugar** abre `scenes/exploration/Mundo3D.tscn`, un mundo 3D completo construido a partir del documento
  de diseño de 20 páginas. Cubre el núcleo:
  - Árbol del Eco: nido del jugador, rama madre, anillo de pasarelas, puente de yute, mirador de la ceiba
    y escalera.
  - Aldea Baja: plaza, pozo tejido, mercado, Doña Cresta, Abuelo Espolón, piedra grabada y niños.
  - Cenote Azul: puente de piedra, altar del guajolote y entrada del santuario.
  - Camino Secreto: túnel, glifos de pluma, orquídea y guardián con cortina de lianas.
  - Claro de la Estatua del Guajolote.
- Las demás zonas del documento se ven como vistas lejanas: volcán, sierras, Zona Prohibida, Acantilado
  del Cráneo, cementerio y pirámides.
- Generación en Blender por código: `blender/mundo3d/scripts/build_mundo.py` exporta `mundo.glb`,
  `biblioteca.glb` y `mundo.json`.
- En Godot (`scripts/mundo/`):
  - Shaders propios para PBR con musgo, terreno, hojas, agua del cenote y montañas.
  - Vegetación en MultiMesh por zonas.
  - Zonas caminables.
  - Ciclo de día, con la hora elegible en la pausa.

### Historia y cámaras

- Historia completa: despertar, revelación desde el mirador, ofrenda de maíz, altar, guardián, encuentro
  con el Pollo Negro, combate, regreso y revancha.
- Director de cámaras por zonas: planos fijos, raíles, seguimiento y grúas.
- El jugador sube escalones y conserva la dirección tras un corte de cámara.

### Combate

- El combate se libra en el claro de la estatua del mismo mundo y con la misma hora. El menú principal
  también muestra ese claro.

### Selva tropical

- Árboles con contrafuertes, lianas hasta el suelo, bromelias y musgo en la base.
- Palmas, helechos arborescentes, plataneras y monsteras junto a los caminos, con un atlas de hojas
  tropicales generado por código.
- La vegetación alta no se coloca entre las cámaras fijas y lo que miran.
- Colores algo desaturados.

### Correcciones visuales

- El agua del cenote ya no se ve blanca en Compatibility.
- Nuevos encuadres para la revelación, el altar del cenote y la grúa del guardián.
- El altar ya no queda tapado por rocas.

### Eliminado

- Se eliminó la exploración prerrenderizada anterior: `SelvaCinematica.tscn`, `cinematic_jungle.gd`,
  `selva_fx.gd`, `selva_mundo.gd`, `assets/backgrounds/selva` y sus shaders.
- Se eliminó la arena de combate exportada (`assets/arena`, `arena_pbr.gdshader`, `export_arena.py`). El
  mundo 3D las sustituye.

### Pruebas

- `--mode=mundo` recorre a pie toda la ruta con el joystick virtual, hace todas las interacciones, el
  combate y el regreso.
- Herramientas de revisión en `tests/tools/`.

## Look cinematográfico: claroscuro, pintura, atmósfera y cámaras (2026-10-23)
- Renderizador **Forward+ en PC** (el objetivo del juego); en móviles se mantiene Compatibility para poder
  seguir probando en iPhone/Xogot (`rendering_method.mobile`).
- `scripts/core/cinematic_look.gd`: entorno común con claroscuro. El sol principal es más fuerte, con sombras
  suaves (penumbra) y menos luz de relleno. Incluye oclusión ambiental (SSAO), reflejos de pantalla (SSR)
  en la arena, niebla volumétrica en la arena, resplandor y ajuste de contraste. También añade
  profundidad de campo, que enfoca a los personajes y desenfoca el fondo.
- Filtro pictórico a pantalla completa (`assets/materials/post/pintura.gdshader`). Usa un filtro de
  Kuwahara (pinceladas), textura de trazo y lienzo, y una paleta desaturada en la que los rojos, naranjas
  y dorados conservan su intensidad (los pollos, el fuego y los faroles). Añade también curva de contraste,
  sombras frías y luces cálidas, viñeta y grano de película. Va por debajo del HUD y se activa o desactiva
  en la pausa con **Filtro pictórico: Sí/No**.
- Exploración: bruma animada sobre los fondos prerrenderizados (crece con la profundidad real del render)
  y **seguimiento lento** dentro de cada plano fijo. El encuadre se recorta un 14 % y acompaña al jugador con
  suavidad, sin salir nunca de la imagen; los cortes entre planos siguen igual.
- Combate: leve movimiento de cámara al hombro y enfoque automático al sujeto de cada plano.
- Pruebas nuevas: filtro activo en exploración y combate, activar y desactivar el filtro, profundidad de
  campo y seguimiento lento en la plaza.

## Corrección: cruzar el puente de piedra (2026-10-23)
- El Pollo Amarillo se quedaba atascado al empezar el puente (x≈2,6): el límite de "no salir del cuadro"
  de la plaza (D1) lo frenaba antes de entrar en la zona del plano del puente (D2). Ahora en la aldea vale
  cualquier punto que se vea en D1 o en D2 (se solapan sobre el puente) y la cámara se mantiene en el
  plano actual hasta que el personaje sale de él, y entonces corta al otro.
- Prueba nueva: cruzar el puente caminando desde la plaza, con corte a D2 y sin salir nunca del cuadro.

## Combate en arena 3D con cámara cinematográfica (2026-10-23)
- El claro del combate es ahora 3D en tiempo real: geometría exportada de la escena de Blender de la aldea
  (`export_arena.py` → `assets/arena/claro.glb`) y entorno lejano como panorama 360° de Cycles. Sol con
  sombras, niebla, agua y cascadas animadas; materiales triplanares con musgo (`arena_pbr.gdshader`).
- Director de cámara (`combat_stage.gd`) con planos con nombre: general (más lejos y más alto), sobre el
  hombro del héroe, a la espalda del enemigo, lateral, contrapicado, impacto, enemigo y victoria. Los giros
  grandes se cortan y los pequeños se interpolan; la vegetación que tapa a los personajes se oculta.
- En el turno del jugador la cámara se acerca a tercera persona sobre el hombro y ahí sale el menú.
- Coreografía de acciones: anticipación, carrera con salto, combo de dos golpes, corte al impacto con
  parada de golpe y retroceso; Pluma Ígnea con contrapicado durante la carga; ataques enemigos vistos desde
  la espalda del enemigo para la parada; entrada con barrido de cámara; victoria en contrapicado.
- El menú principal muestra la arena con una órbita lenta de cámara.
- Eliminados el fondo de combate prerrenderizado (`combat_aldea.png`, `combat_camera.json`,
  `render_combate.py`) y restos antiguos (`combat_jungle.png`, `render_combat_bg.py`).
- Pruebas nuevas: arena cargada, plano sobre el hombro en el turno del jugador, enemigo visible en ese
  plano, corte al impacto y plano de la parada.

## Todo prerrenderizado + corrección del movimiento en la plaza (2026-10-23)
- Corregido: al bajar a la plaza el Pollo Amarillo aparecía fuera del encuadre (debajo de la cámara), por
  lo que en el iPhone parecía que no se podía mover. Ahora llega dentro del cuadro y, en la aldea, el límite
  de navegación impide salir de lo que ve la cámara activa.
- Eliminada la "Selva clásica" (escena 3D de cámara libre y su código); todo el juego usa fondos
  prerrenderizados, con *Baten Kaitos* como referencia.
- Nuevo fondo de combate renderizado en el claro del guardián de la aldea (`render_combate.py`); el menú
  usa el mismo escenario.
- Pruebas nuevas: personaje visible en cada plano, joystick en cuatro direcciones en la plaza, intento de
  salir del cuadro, pausa en exploración. El recorrido de combate completo usa ahora la aldea.

## Aldea del Árbol Ancestral — selva cinematográfica prerrenderizada (2026-10-23)
- **Jugar** abre la nueva zona de cámaras fijas: interior de la cabaña → puerta animada → porche →
  la gran rama (modo equilibrio) → revelación panorámica de la aldea → plaza y puente de piedra →
  encuentro con el Pollo Negro → combate por turnos → regreso con revancha.
- Fondos renderizados en Blender (Cycles) con mapa de profundidad: los personajes 3D quedan ocultos
  detrás de los elementos del fondo. Escena de Blender y scripts para regenerarlo todo en
  `blender/selva_cinematica/`.
- Movimiento con peso en cámara fija: aceleración y frenado suaves, giro antes de avanzar, inclinación,
  equilibrio en la parte estrecha de la rama (más lento, balanceo, pausas, restricción lateral) y límites
  de navegación por zona. El control es relativo a la cámara y estable en los cortes.
- Cinco interacciones en la aldea con diálogos nuevos (pozo, frutera, anciano, piedra grabada, cabaña de
  piedra); el guardián aparece tras tres.
- Efectos en tiempo real: agua del lago, arroyo y pozo; cascadas con bruma y salpicaduras; hojas que caen;
  ramitas que se mecen; rayos de luz; polvo, polen, luciérnagas y aves; luz que entra por la puerta.
- "Continuar" tras un combate vuelve a la zona de exploración.
- Pruebas: nuevo recorrido automático `--mode=selva` incluido en `--mode=all`.

## iPhone / Xogot - cámara táctil
- Se añadió giro de cámara por gesto de arrastre en la mitad derecha libre de la pantalla.
- El gesto vertical ajusta la inclinación con límites para evitar invertir la cámara.
- El joystick, RUN, USAR y los controles de teclado existentes se mantienen.
- Se agregó el grupo `player_camera` y el método `rotate_from_touch()` al rig de cámara.
- Validación realizada en este paquete: integridad del ZIP y revisión estática de archivos. No se pudo ejecutar Godot/Xogot en este entorno ni confirmar el comportamiento en un iPhone físico.
