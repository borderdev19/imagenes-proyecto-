# Etapa C · Entorno selvático anime: informe técnico

**Fecha:** 30 de octubre de 2026
**Estado:** revisión C3 terminada y en espera de tu revisión. No está integrada en el mundo principal y no he empezado otra etapa.

El informe tiene tres partes, de la más reciente a la más antigua: **C3**, **C2** y **C1**. Las capturas de C1 y C2 se conservan sin cambios.

---

## Revisión C3

### C3.0 Punto de partida y alcance
- Antes de cambiar nada revisé la escena, los scripts y los shaders de la C2. La C3 se construye **encima** de la C2, sin modificarla:
  - `PruebaEntornoC3` hereda de `PruebaEntornoC2`.
  - `SelvaC3` reutiliza los tubos, racimos, lianas, rocas y suelo de `SelvaC2`.
  - El suelo C3 es una copia ampliada del shader C2.
- La escena C2, la C1, el laboratorio de la Etapa B, el juego y el mundo principal **no se han tocado**. No hay cambios de gameplay, personajes, animaciones, controles, cámara del juego, combate, diálogos ni HUD.
- Escena nueva e independiente: `scenes/pruebas/PruebaEntornoAnimeC3.tscn`. Usa los mismos encuadres y horas que la C2, y añade uno de raíces y rocas, para comparar directamente.
- Todo se validó con **Godot 4.7.2** (4.7.2.stable.official.ed1daf0bf), Forward+.

### C3.A Variedad de árboles y copas
- Hay **4 especies nuevas** con siluetas claramente distintas. Junto con las 3 de la C2 y las palmas, dan 8 tipos en el bosque cercano:

  | Especie | Silueta |
  |---|---|
  | **Monumental** (higuera gigante) | 26-33 m, tronco de 4-5 fustes trenzados alrededor de un núcleo, 8-10 raíces que serpentean por el suelo, raíces aéreas que bajan de las ramas, copa ancha en dos capas y muchas lianas |
  | **En pisos** | Tronco recto con 3-4 verticilos de ramas horizontales; copa plana por pisos (pagoda) |
  | **Cecropia** | Tronco fino y claro con raíces zanco, 3-5 ramas en candelabro y rosetas planas en las puntas |
  | **Inclinado** | Tronco que sube y se curva; copa alargada al final. Se orienta hacia el camino para enmarcarlo |
  | Ceiba, redonda y joven (C2) | Se conservan |

- **Transición tronco, ramas y follaje:** en las especies nuevas cada rama termina en 2-3 ramitas, cada una con su racimo, y lleva un racimo menor a media rama. El follaje nace de la madera y no flota sobre ella.
- **Sin copias:**
  - Hay 28 variantes, cada una con su semilla.
  - Al colocarlas se giran y se escalan **de forma no uniforme**: la altura varía del 85 al 120 % respecto al ancho.
  - Cada variante tiene su propio par de verdes.
- **Recuento del bosque cercano:** 149 árboles y palmas: 36 redondos, 31 cecropias, 30 jóvenes, 19 en pisos, 19 palmas, 7 ceibas, 4 monumentales y 3 inclinados. El anillo lejano tiene 190 árboles de 4 especies.

### C3.B Vegetación del primer plano
- **Plantas grandes más contenidas:**
  - Escalas: monstera 0,9-1,05 (antes 1,3-1,6), platanera 0,7 (antes 0,9) y helecho arborescente 0,55-0,6 (antes 0,6-0,7).
  - Siempre a **3 m o más del eje del camino** (antes 2,2 m).
- **Zonas libres delante de cada cámara:** en los primeros 4,5 m de cada encuadre, y alrededor del personaje, no crecen plantas grandes ni árboles. Una prueba lo comprueba sobre las 150 plantas grandes.
- **Plantas pequeñas más bajas en la orilla:** helecho 1,8 (antes 2,3) e hierba 3,0 (antes 3,6). Hay más calatheas y anthuriums para variar especies y alturas.
- **Lectura del camino:** el camino queda despejado y el personaje se lee entero en el plano de escala, de día y de noche.

### C3.C Noche cinematográfica
La exposición general **no se ha subido**: es la misma de día y de noche, y una prueba lo verifica. La lectura nocturna viene de luz selectiva:
- **Luna** más presente y fría (energía 0,72, azul), con sombras.
- **Ambiente verde azulado** (0,32 · 0,46 · 0,58, energía 0,62).
- **Bruma nocturna azul más clara que el cielo:** las siluetas de los árboles se separan por capas de profundidad.
- **Borde de luz de luna en las copas:** un rim frío que dibuja la silueta de las hojas.
- **Camino con algo más de valor de noche** (+35 % solo en la tierra del camino), para poder orientarse.
- **220 luciérnagas** a lo largo del camino, aditivas y con parpadeo, más **3 luces suaves verdosas** junto al camino. Todo se apaga de día.
- El amanecer y el anochecer pasan por una rampa (19:00-20:30 y 4:30-6:00).

### C3.D Suelo, raíces y rocas
- **Raíces expuestas:**
  - 56 raíces salen de los árboles cercanos hacia la orilla del camino, medio enterradas, y **no cruzan el centro del camino**, que se sigue pudiendo recorrer (comprobado en una prueba).
  - A ellas se suman las 8-10 raíces de cada árbol monumental y las raíces de los inclinados.
- **Rocas integradas:**
  - 9 grupos, cada uno con una roca mayor, rocas medianas y 5-9 piedrecillas, más 22 piedras sueltas: 57 rocas en total.
  - Hundidas un 18 % de su altura y con leve inclinación.
  - El suelo marca **tierra húmeda oscura al pie de cada roca y un anillo roto de musgo** alrededor.
  - Hay grupos al pie del árbol monumental y junto a sus raíces.
- **Camino:**
  - Orilla más irregular, rota a dos escalas.
  - Dos roderas compactas a lo largo del camino.
  - Piedrecillas cerca de la cámara.
- **Transiciones:** una franja de musgo entre la hojarasca y la hierba sustituye el corte directo.

### C3.E Identidad y escala
- **Árbol monumental como punto focal** al fondo del camino, unos 60 m por delante del encuadre general. Un **corredor de vista** sin árboles permite verlo desde el inicio del recorrido.
- **Dos árboles inclinados** que se arquean sobre el camino y lo enmarcan.
- **Lianas** que cruzan por encima del camino entre las copas de ambos lados, con tramos colgantes.
- **Vegetación en varios planos:** primer plano bajo, árboles medianos, emergentes, anillo lejano y masa de copas del horizonte.
- No se añadió ninguna estructura ni construcción.

### C3.F Rendimiento y arquitectura
- Los árboles, las plantas grandes y las rocas pasan a **MultiMesh**:
  - Árboles: una por variante y por sector de 60 m.
  - Plantas grandes y palmas: una por planta.
  - Rocas: una por forma y material.
  - Los materiales se comparten entre variantes y no se duplican.
- Por qué hay sectores: una sola MultiMesh para todo el bosque se dibujaba entera aunque la cámara no la viera, y los triángulos se triplicaban (3,8 M). Con sectores, la cámara y las sombras descartan lo que no ven.
- El **anillo lejano no proyecta sombras**, porque queda dentro de la bruma.
- Nodos de dibujo en escena: **C2 467, C3 312**. La prueba lo comprueba.
- Medición con `-- --medir=20` en el plano general a 1600×900 ([pruebas_c3/rendimiento_medido_472.txt](pruebas_c3/rendimiento_medido_472.txt)):

  | Escena | Llamadas de dibujo | Triángulos | ms/fotograma (llvmpipe) |
  |---|---|---|---|
  | C2 | 961 | 1 167 747 | 4913,62 |
  | C3 | 765 (−20 %) | 1 348 843 (+15 %) | 5170,52 |

- **Importante:** estas cifras son de un contenedor **sin GPU** (Mesa llvmpipe por CPU, Intel Xeon 2,1 GHz, 4 núcleos). Los ms y los FPS **no representan un PC con tarjeta gráfica** y no deben usarse como prueba de rendimiento. Solo comparan llamadas de dibujo y triángulos entre versiones. La prueba en GPU real queda pendiente, como indicaste.

### C3.G Capturas reales de Godot 4.7.2 (Forward+)
Son 17 capturas a 1600×900, tomadas desde la escena C3 con cámara y hora fijas. No son imágenes generadas ni retocadas. Las láminas solo ponen dos capturas una al lado de la otra.

| # | Pedido | Captura C3 | C2 vs C3 |
|---|---|---|---|
| 1 | General de día | [c3](capturas_c3/c3_anime_general_h13_0.jpg) | [lámina](comparaciones_c3/c2_vs_c3_general_h13_0.jpg) |
| 2 | General al amanecer | [c3](capturas_c3/c3_anime_general_h06_5.jpg) | [lámina](comparaciones_c3/c2_vs_c3_general_h06_5.jpg) |
| 3 | General al atardecer | [c3](capturas_c3/c3_anime_general_h18_2.jpg) | [lámina](comparaciones_c3/c2_vs_c3_general_h18_2.jpg) |
| 4 | General de noche | [21 h](capturas_c3/c3_anime_general_h21_0.jpg), [0 h](capturas_c3/c3_anime_general_h00_0.jpg) | [21 h](comparaciones_c3/c2_vs_c3_general_h21_0.jpg), [0 h](comparaciones_c3/c2_vs_c3_general_h00_0.jpg) |
| 5 | Copas | [c3](capturas_c3/c3_anime_copas_h13_0.jpg) | [lámina](comparaciones_c3/c2_vs_c3_copas_h13_0.jpg) |
| 6 | Vegetación del suelo | [día](capturas_c3/c3_anime_vegetacion_h13_0.jpg), [noche](capturas_c3/c3_anime_vegetacion_h21_0.jpg) | [lámina](comparaciones_c3/c2_vs_c3_vegetacion_h13_0.jpg) |
| 7 | Raíces y rocas | [raíces](capturas_c3/c3_anime_raices_h13_0.jpg), [rocas](capturas_c3/c3_anime_rocas_h13_0.jpg) | [raíces](comparaciones_c3/c2_vs_c3_raices_h13_0.jpg), [rocas](comparaciones_c3/c2_vs_c3_rocas_h13_0.jpg) |
| 8 | Vista elevada | [c3](capturas_c3/c3_anime_profundidad_h13_0.jpg) | [lámina](comparaciones_c3/c2_vs_c3_profundidad_h13_0.jpg) |
| 9 | Personaje y escala | [día](capturas_c3/c3_anime_escala_h13_0.jpg), [noche](capturas_c3/c3_anime_escala_h21_0.jpg) | [lámina](comparaciones_c3/c2_vs_c3_escala_h13_0.jpg) |
| 10 | C2 vs C3 | 12 láminas en `comparaciones_c3/` | [ciclo C3](comparaciones_c3/c3_ciclo_dia_noche.jpg) |

![General](comparaciones_c3/c2_vs_c3_general_h13_0.jpg)
![Noche](comparaciones_c3/c2_vs_c3_general_h21_0.jpg)
![Raíces](comparaciones_c3/c2_vs_c3_raices_h13_0.jpg)
![Ciclo](comparaciones_c3/c3_ciclo_dia_noche.jpg)

### C3.H Pruebas funcionales (Godot 4.7.2)
- **Suite completa `--mode=all`:** **317 de 317 correctas** ([pruebas_c3/resultado_pruebas_mode_all_472.txt](pruebas_c3/resultado_pruebas_mode_all_472.txt)). Son las 296 anteriores más **21 nuevas** de la C3. Las anteriores cubren los sistemas del juego: personajes, combate, diálogos, HUD, guardado y mundo.
- **Pruebas nuevas de la C3:**
  - **Carga y shaders:** la escena carga, los shaders de suelo y luciérnagas compilan, y no hay objetos de laboratorio.
  - **Árboles:** monumental de más de 25 m con raíces, pisos, cecropia e inclinado con su silueta, alturas distintas, 8 tipos en el bosque y MultiMesh.
  - **Primer plano y suelo:** plantas grandes fuera del camino y de las cámaras, raíces que no bloquean el centro del camino, y rocas en grupos.
  - **Noche:** luciérnagas y luces solo de noche, noche legible sin subir la exposición, y bruma más clara que el cielo.
  - **Personaje:** está en el camino, visible en el plano de escala y oculto en los demás.
  - **Rendimiento:** menos nodos de dibujo que la C2.
- **Ciclo día-noche:** probado a las 6:30, 9, 13, 16:30, 18:12, 19:30, 21 y 0 h, en capturas y en pruebas.
- **Consola de Forward+ durante las capturas:** sin errores de scripts, shaders ni recursos faltantes. Solo aparecen los avisos de audio ALSA (el contenedor no tiene tarjeta de sonido). Registro en [pruebas_c3/consola_capturas_forward_plus_472.txt](pruebas_c3/consola_capturas_forward_plus_472.txt).
- **Cámara del juego y gameplay:** no se han modificado. Las cámaras de la escena de prueba son encuadres fijos de evaluación.

### C3.I Problemas pendientes
- **Rendimiento en GPU real:** pendiente, como indicaste.
- **Triángulos:** la C3 tiene un 15 % más de triángulos que la C2, por el bosque más rico, los árboles monumentales, las raíces y las rocas, aunque hace un 20 % menos de llamadas de dibujo. Si en el PC hiciera falta, el siguiente paso sería un LOD del anillo lejano (variantes con menos racimos).
- **Encuadre de terreno:** a la derecha entra una copa cercana desde arriba. Se lee como marco natural, pero se puede despejar más si lo prefieres.
- **Copas de cerca:** el atlas de hojas sigue siendo procedural. Un atlas pintado a mano daría más carácter en primer plano.
- **Amanecer y atardecer:** siguen teniendo una paleta parecida, como ya anoté en la C2.
- **Sin integrar:** la C3 no está en el mundo principal, como pediste.

### C3.J Archivos
Nuevos:
- `scenes/pruebas/PruebaEntornoAnimeC3.tscn`
- `scripts/anime/prueba_entorno_c3.gd`
- `scripts/anime/selva_c3.gd`
- `assets/materials/anime/anime_suelo_selva_c3.gdshader`
- `assets/materials/anime/anime_luciernaga.gdshader`
- `tests/entorno_c3_tests.gd`

Modificados:
- `tests/e2e_director.gd`: ejecuta también las pruebas C3.
- `CHANGELOG.md`

Ningún archivo de la C2, la C1, la Etapa B ni el v13 cambió. El detalle está en [ARCHIVOS.md](ARCHIVOS.md).

Para abrir la escena: `res://scenes/pruebas/PruebaEntornoAnimeC3.tscn` (F6). Las teclas son:
- **1 a 8:** encuadres (el 8 es raíces y rocas).
- **H:** cambia la hora.
- **O:** activa o desactiva los contornos.
- **Esc:** vuelve al menú.

---

## Revisión C2

La C2 es una escena de prueba nueva y aislada, `scenes/pruebas/PruebaEntornoAnimeC2.tscn`. No toca la
escena C1, el laboratorio de la Etapa B, el juego ni el mundo principal. Con Tab se compara con el v13
en el mismo sitio, con la misma cámara y la misma hora: el v13 muestra sus árboles `ArbolSelva`, sus
rocas escaneadas y su material de terreno originales donde el estilo anime pone los nuevos.

**Validación con Godot 4.7.2** (4.7.2.stable.official.ed1daf0bf), la versión objetivo. La importación,
las pruebas, las capturas y la medición de la C2 se hicieron con esa versión. Ninguna prueba necesitó
otra versión. (La C1 se había validado con 4.7 stable porque entonces no tenía la 4.7.2 disponible.)

### C2.1 Copas: árboles de verdad, no esferas
- Se eliminaron las masas de copa esféricas de la C1. Los árboles de la C2 son **mallas nuevas**: tronco
  con ramas reales que salen de él, y la copa formada por **racimos de hojas** (tarjetas con una
  textura de hojas recortadas, en 4 variantes) agrupados al final de cada rama.
- Cada racimo tiene un tamaño, un aplastamiento y una orientación distintos, y las normales de la copa
  apuntan hacia fuera del racimo. Así la luz forma bandas de volumen (sol arriba, sombra fría abajo),
  pero el borde de la silueta queda recortado por hojas, no liso.
- Ninguna forma se repite: cada árbol se genera con su propia semilla. Hay 19 variantes, y al
  colocarlas se giran y escalan. Una prueba comprueba que dos semillas dan árboles distintos.

### C2.2 Bosque: densidad, especies y espacio jugable
- **Tres especies** con siluetas propias:
  - **Ceiba:** 16–22 m, raíces de tabla, ramas casi horizontales y copa ancha y plana.
  - **Árbol de copa redonda:** 5–8 m, tronco corto y ramas que suben.
  - **Árbol joven:** 6–9 m, delgado y con racimos apilados.
  - A esas tres se suman palmas, helechos arborescentes, plataneras y monsteras de la biblioteca.
- **Especies según la distancia al camino:** cerca dominan los árboles redondos, los jóvenes y las
  palmas. Lejos aparecen más ceibas.
- **Recuento:** 117 árboles cercanos (10 ceibas, 59 redondos y 48 jóvenes) y 20 palmas, con
  separación mínima por especie. Detrás hay un anillo de 190 árboles lejanos y una masa continua de
  copas en el horizonte.
- **Sotobosque en manchas:** helechos, hierbas altas, calatheas, anthuriums y arbustos se agrupan en las
  orillas del camino, al pie de los árboles y en los claros.
- **Zona jugable:** el camino serpenteante (2,6 m de ancho) y sus orillas quedan libres, igual que el
  primer plano de la cámara, así que la escena se lee como un recorrido jugable.

### C2.3 Terreno: zonas naturales sin manchas pastel
- Nuevo shader `anime_suelo_selva.gdshader`, sin texturas fotográficas y sin degradados difuminados.
  Las zonas tienen **borde definido**, roto por ruido a dos escalas para que no salgan discos ni
  manchas redondas.
- **Paleta natural** con variación controlada: tierra del camino en dos tonos, hojarasca (con hojas
  sueltas cerca de la cámara), musgo y charcos de humedad bajo las copas, y tres tonos de hierba
  (verde, claro y seco).
- El suelo se unifica hacia un verde de distancia para no hacer ruido a lo lejos. La malla tiene un
  relieve suave (unos 35 cm) y el camino va ligeramente hundido.

### C2.4 Rocas facetadas y asentadas
- Las rocas nuevas parten de una icosfera de pocas caras. Se recortan con **7 a 10 planos**, que dejan
  caras planas y aristas, y usan normales de cara, así que con las bandas de luz se ven los planos.
- Hay **tamaños variados**: rocas grandes de hasta unos 3 m de ancho, medianas, pequeñas y piedras sueltas. Se reparten
  en cinco grupos junto al camino y 14 piedras sueltas, 28 en total.
- **Base aplanada y hundida** un 12 % en el suelo.
- **Musgo solo en lo alto** de las rocas grandes de los grupos en sombra, con un verde oscuro.
- Las plantas no crecen encima de las rocas.

### C2.5 Horizonte sin franja azul
- El cielo anime tiene su horizonte mezclado con el color de la bruma. Además, el horizonte del suelo
  del cielo y la niebla son **exactamente el mismo color**, y hay una prueba que lo verifica.
- Detrás del bosque cercano hay **190 árboles lejanos** (entre 58 y 200 m) y una **masa continua de
  copas** a 175–235 m. Entre los troncos ya no se ve ni el cielo ni el final del suelo: la selva sigue
  hasta perderse en la bruma.
- La niebla de profundidad va de 22 a 160 m, con una perspectiva aérea suave.

### C2.6 Cielo e iluminación por hora
- La **tabla de luz anime** tiene 9 horas: 0, 5:30, 6:30, 9, 13, 16:30, 18:12, 19:30 y 24. Cada hora
  fija el cenit, el horizonte, la bruma, el color y la energía del sol, su altura y dirección, y el
  ambiente. Los valores intermedios se interpolan.
- **Mediodía:** cenit azul con saturación contenida (0,17 · 0,40 · 0,74). El sol entra en diagonal
  (58° de altura) para que haya sombras y volumen; con el sol cenital todo quedaba plano.
- **Atardecer y amanecer:** el cielo toma tonos cálidos y violetas, pero la luz del sol conserva el
  verde (≥ 0,7), así que la vegetación no se tiñe de rosa ni de amarillo.
- **Noche:** luz de luna azulada con energía 0,5 y ambiente 0,55. El camino, los troncos y el sotobosque
  se distinguen.
- Ajustes del entorno anime C2: ambiente de color en lugar de cielo, SSAO más marcado, saturación 1,06,
  contraste 1,1 y exposición 1,0.
- Hay capturas del ciclo completo en los dos estilos (ver C2.8).

### C2.7 Corrección de color encontrada en la C2
Los colores que se pasan a los materiales como `Vector3` llegan al shader **sin convertir de sRGB a
lineal**. Por eso en la C1 las rocas y las cortezas salían casi blancas y las copas, verde menta. En la
C2 los colores de copas, cortezas, rocas y musgo se convierten a lineal antes de pasarlos. Los
materiales de la Etapa B no se tocaron.

### C2.8 Capturas reales de Godot 4.7.2 (Forward+)
Son 28 capturas a 1600×900. Hay 7 encuadres al mediodía en los dos estilos, y el plano general a 7
horas más en los dos estilos. Todas salen de la escena de prueba con la cámara y la hora fijas: no son
renders externos, imágenes generadas ni retoques. Las láminas solo ponen dos capturas una al lado de
la otra. La escena no tiene esferas, tablones ni objetos de laboratorio, y el personaje solo aparece
en el plano de escala.

| Encuadre | Anime C2 | v13 | Comparación |
|---|---|---|---|
| Vista general | [anime](capturas_c2/c2_anime_general_h13_0.jpg) | [v13](capturas_c2/c2_v13_general_h13_0.jpg) | [lámina](comparaciones_c2/c2_comparacion_general_h13.jpg) |
| Profundidad (elevada) | [anime](capturas_c2/c2_anime_profundidad_h13_0.jpg) | [v13](capturas_c2/c2_v13_profundidad_h13_0.jpg) | [lámina](comparaciones_c2/c2_comparacion_profundidad_h13.jpg) |
| Copas | [anime](capturas_c2/c2_anime_copas_h13_0.jpg) | [v13](capturas_c2/c2_v13_copas_h13_0.jpg) | [lámina](comparaciones_c2/c2_comparacion_copas_h13.jpg) |
| Vegetación | [anime](capturas_c2/c2_anime_vegetacion_h13_0.jpg) | [v13](capturas_c2/c2_v13_vegetacion_h13_0.jpg) | [lámina](comparaciones_c2/c2_comparacion_vegetacion_h13.jpg) |
| Rocas | [anime](capturas_c2/c2_anime_rocas_h13_0.jpg) | [v13](capturas_c2/c2_v13_rocas_h13_0.jpg) | [lámina](comparaciones_c2/c2_comparacion_rocas_h13.jpg) |
| Terreno | [anime](capturas_c2/c2_anime_terreno_h13_0.jpg) | [v13](capturas_c2/c2_v13_terreno_h13_0.jpg) | [lámina](comparaciones_c2/c2_comparacion_terreno_h13.jpg) |
| Escala con el personaje | [anime](capturas_c2/c2_anime_escala_h13_0.jpg) | [v13](capturas_c2/c2_v13_escala_h13_0.jpg) | [lámina](comparaciones_c2/c2_comparacion_escala_h13.jpg) |
| Ciclo día-noche | [anime, 8 horas](comparaciones_c2/c2_ciclo_dia_noche_anime.jpg) | [v13, 8 horas](comparaciones_c2/c2_ciclo_dia_noche_v13.jpg) | 6:30, 9, 13, 16:30, 18:12, 19:30, 21 y 0 h |

![General](comparaciones_c2/c2_comparacion_general_h13.jpg)
![Profundidad](comparaciones_c2/c2_comparacion_profundidad_h13.jpg)
![Rocas](comparaciones_c2/c2_comparacion_rocas_h13.jpg)
![Ciclo anime](comparaciones_c2/c2_ciclo_dia_noche_anime.jpg)

### C2.9 Validación técnica (Godot 4.7.2)
- **Pruebas automatizadas:** **296 de 296 correctas** en `--mode=all` (headless). Son las 276 anteriores más **20
  nuevas** de la C2, en [pruebas_c2/resultado_pruebas_mode_all_472.txt](pruebas_c2/resultado_pruebas_mode_all_472.txt).
  - Compilación de los shaders de copa y suelo.
  - Árboles de las tres especies con tronco y copa, alturas distintas y sin clones.
  - Rocas con normales hacia fuera, facetadas y con la base hundida.
  - Escena sin objetos de laboratorio, con las especies y el anillo lejano.
  - Horizonte sin franja azul, y suelo del cielo igual a la niebla.
  - Cielo de mediodía con saturación contenida, atardecer sin tinte rosa y noche legible.
  - Cambio de estilo v13 ↔ anime.
- **Consola de Forward+ durante las 28 capturas:** sin errores ni advertencias de scripts, shaders o
  recursos. Solo aparecen los avisos de audio ALSA, porque el contenedor no tiene tarjeta de sonido.
  Registro en [pruebas_c2/consola_capturas_forward_plus_472.txt](pruebas_c2/consola_capturas_forward_plus_472.txt).
- **Rendimiento:** medido con `-- --medir=20` sobre el plano general a 1600×900, sin límite de FPS
  ([pruebas_c2/rendimiento_medido_472.txt](pruebas_c2/rendimiento_medido_472.txt)):

  | Estilo | ms/fotograma | FPS | Llamadas de dibujo | Triángulos |
  |---|---|---|---|---|
  | v13 (mismo sitio, árboles y rocas v13) | 5805,49 | 0,17 | 638 | 2 881 429 |
  | Anime C2 | 4913,62 | 0,20 | 961 | 1 167 747 |

  **Entorno de la medición:** contenedor en la nube **sin GPU**, con Intel Xeon a 2,1 GHz (4 núcleos) y
  15 GB de RAM. Vulkan por software (Mesa llvmpipe, LLVM 20.1.2) en Xvfb, con Godot 4.7.2 stable
  oficial. Estos FPS **no representan un PC con tarjeta gráfica** y no deben usarse como cifra de
  rendimiento: solo sirven para comparar entre estilos en la misma máquina. En la misma escena, la
  versión anime dibuja **un 59 % menos de triángulos** que el v13 (los árboles escaneados del v13 son
  más pesados), pero hace **un 51 % más de llamadas de dibujo** (961 frente a 638), porque cada árbol
  procedural es una malla independiente.

### C2.10 Pendiente y limitaciones
- **Sin GPU real:** no se puede dar una cifra de FPS para un PC. Hay que medir `-- --medir=120` en el PC
  de destino. Los más de 300 árboles son mallas sueltas; si el coste lo pide, el siguiente paso sería
  agruparlos (MultiMesh por variante) o usar LOD para el anillo lejano.
- **Hojas muy cerca de la cámara:** con el renderizado por software, los helechos pegados a la cámara
  muestran algo de dentado en las hojas finas. En un PC con antialiasing debería verse más limpio; no
  lo he podido comprobar.
- **Atlas de hojas generado por código:** el racimo de hojas es una textura procedural. Una versión
  pintada a mano o modelada en Blender daría más carácter a las copas de primer plano.
- **Atardecer:** el amanecer (6:30) y el atardecer (18:12) comparten una paleta violeta muy parecida.
  Se podrían diferenciar más si quieres.
- **Sin integrar:** como pediste, nada de esto está en el mundo principal.

### C2.11 Cómo abrirla
Abre `res://scenes/pruebas/PruebaEntornoAnimeC2.tscn` y ejecútala (F6). Las teclas son:
- **Tab:** cambia entre v13 y anime.
- **1 a 7:** cambia el encuadre.
- **H:** cambia la hora.
- **O:** activa o desactiva los contornos.
- **Esc:** vuelve al menú.

Para capturas y medición:
```
godot --path . res://scenes/pruebas/PruebaEntornoAnimeC2.tscn -- --capturas=/ruta
godot --path . res://scenes/pruebas/PruebaEntornoAnimeC2.tscn -- --medir=120
```

---

## Versión C1 (primera entrega, conservada como referencia)

**Fecha:** 30 de octubre de 2026
**Base:** la copia de desarrollo de la Etapa B. La v13 entregada y su copia de seguridad siguen intactas.
**Estado:** sustituida por la revisión C2 (arriba); se conserva como referencia.

Todo el trabajo está en una escena de prueba nueva, `scenes/pruebas/PruebaEntornoAnime.tscn`. El juego, el
mundo jugable y el laboratorio de la Etapa B no cambian. En la escena, la tecla Tab alterna entre el
estilo v13 original y el estilo anime para comparar.

### 1. Resultado por área

#### Vegetación y árboles
- Se añadió un bosque de fondo con 2 árboles fijos y 14 repartidos con semilla fija. Usan las 8 variantes
  de `ArbolSelva` de la biblioteca, con tamaño y giro variados. El centro de la escena y el recorrido de la
  cámara quedan libres, para no tapar el espacio jugable.
- Cada árbol lleva 6 **masas de copa volumétricas**: esferas deformadas con lóbulos de ruido, en 6 tonos
  de verde, colocadas en el centro real de la copa (que se lee del GLB). La copa se lee como un volumen
  con bandas de luz y sombra, y no como hojas planas dispersas. Las hojas originales se mantienen alrededor
  para conservar el borde recortado.
- Las copas proyectan sombras grandes. Al mediodía dejan una sombra moteada sobre el suelo.

#### Rocas y superficies naturales
- Las rocas escaneadas usan ahora un color plano propio, sin la foto, y la línea de contorno solo en la
  silueta. Así desaparecen las motas y las líneas interiores.
- La roca grande (`V_boulder_01_0`) y el conjunto con musgo (`V_rock_moss_set_01_0`) tienen
  **microrrelieve de escaneo**: con el sombreado por bandas, cada bulto se convierte en una mota de luz o
  sombra. En la escena de prueba se **sustituyen** por rocas estilizadas en el mismo sitio. Los escaneos
  originales no se modifican.
- Se añadieron 7 rocas estilizadas procedurales: relieve suave a dos escalas, base aplanada y musgo como
  masa de color en la parte superior.

#### Terreno
- Se sustituyó el plano verde uniforme por una malla de 260 m con **parches de color por vértice**:
  musgo, hierba, hojarasca, tierra y zonas húmedas. Dentro de cada parche hay una variación de tono a dos
  escalas. No usa texturas fotográficas.
- El relieve es muy suave (unos 12 cm), así que el espacio jugable sigue leyéndose como plano.

#### Cielo e iluminación
- El estilo anime tiene un **cielo propio**, con una paleta por hora (9, 13, 16:30, 18:12 y 21 h)
  interpolada a lo largo del ciclo. El v13 conserva su cielo de siempre.
- **Mediodía:** el cenit es azul saturado y no blanco. Se subieron la saturación (1,16) y el contraste
  (1,06) sin subir la exposición, para evitar los blancos quemados.
- **Bruma de selva:** la niebla y el horizonte del suelo comparten un color verde grisáceo. Así el final
  del terreno no se ve como un mar azul ni como una franja. De noche, la bruma se oscurece con el cielo.

#### Materiales
Cada familia tiene una identidad propia:

| Material | Acabado |
|---|---|
| Madera (tablones, mimbre) | Color plano con la veta pintada (Etapa B) |
| Troncos (corteza) | Marrón rojizo, detalle pintado y musgo en masa |
| Roca | Gris neutro, sin foto, musgo arriba, contorno solo en la silueta |
| Tierra / suelo | Parches por vértice y bandas, sin textura |
| Copas | Masas en 6 verdes, con 3 bandas |
| Hojas y vegetación | Hojas recortadas con normales esféricas y translucidez (Etapa B) |

### 2. Capturas reales (Godot, Forward+)

Todas se tomaron con Godot desde la escena de prueba, con el viewport a 1600×900. No hay imágenes
generadas, retocadas ni renders externos. Las láminas de comparación solo colocan dos capturas una al
lado de la otra.

| # | Pedido | Archivo |
|---|---|---|
| 1 | Vista general del entorno | [capturas/anime_entorno_general_h16_5.jpg](capturas/anime_entorno_general_h16_5.jpg) |
| 2 | Primer plano de árboles y copas | [capturas/anime_copas_primer_plano.jpg](capturas/anime_copas_primer_plano.jpg) |
| 3 | Primer plano de vegetación | [capturas/anime_vegetacion_primer_plano.jpg](capturas/anime_vegetacion_primer_plano.jpg) |
| 4 | Primer plano de rocas | [capturas/anime_rocas_primer_plano.jpg](capturas/anime_rocas_primer_plano.jpg) |
| 5 | Vista del terreno | [capturas/anime_terreno.jpg](capturas/anime_terreno.jpg) |
| 6 | Iluminación de mediodía | [capturas/anime_iluminacion_mediodia_h13.jpg](capturas/anime_iluminacion_mediodia_h13.jpg) |
| 7 | Otra hora del ciclo | [capturas/anime_ciclo_atardecer_h18_2.jpg](capturas/anime_ciclo_atardecer_h18_2.jpg) y [capturas/anime_ciclo_noche_h21.jpg](capturas/anime_ciclo_noche_h21.jpg) |
| 8 | Comparación original frente a anime | [comparaciones/comparacion_general_h16_5.jpg](comparaciones/comparacion_general_h16_5.jpg), [comparaciones/comparacion_copas.jpg](comparaciones/comparacion_copas.jpg), [comparaciones/comparacion_mediodia_h13.jpg](comparaciones/comparacion_mediodia_h13.jpg) |

![Comparación general](comparaciones/comparacion_general_h16_5.jpg)
![Mediodía](comparaciones/comparacion_mediodia_h13.jpg)
![Copas](comparaciones/comparacion_copas.jpg)

### 3. Validación técnica

- **Pruebas automatizadas:** 276 de 276 correctas en `--mode=all` (headless). Son las 266 anteriores
  (237 originales y 29 de la Etapa B) más **10 nuevas** del entorno: compilación del shader de suelo,
  orientación de caras del suelo, copas y rocas, montaje de la escena, cielo propio frente al del v13,
  azul de mediodía, noche más oscura y estilo v13 intacto. Registro completo en
  [pruebas/resultado_pruebas_mode_all.txt](pruebas/resultado_pruebas_mode_all.txt).
- **Carga de la escena:** carga sin errores de script en headless y en Forward+.
- **Ciclo día-noche:** funciona a las 13, 16:30, 18:12 y 21 h, tanto en las pruebas como en las capturas.
- **Consola de Forward+:** sin errores ni advertencias de scripts, shaders o recursos. Los únicos
  mensajes son los del audio ALSA, porque la máquina no tiene tarjeta de sonido y Godot pasa al
  controlador vacío. Registro en [pruebas/consola_capturas_forward_plus.txt](pruebas/consola_capturas_forward_plus.txt).
- **Rendimiento medido** con `-- --medir=120` sobre el encuadre panorámico a 1600×900, sin límite de FPS
  ([pruebas/rendimiento_medido.txt](pruebas/rendimiento_medido.txt)):

  | Estilo | ms/fotograma | FPS | Llamadas de dibujo | Triángulos |
  |---|---|---|---|---|
  | v13 | 1750,97 | 0,57 | 333 | 750 152 |
  | Anime (Etapa C) | 1029,76 | 0,97 | 394 | 909 690 |

  **Entorno de la medición:** contenedor en la nube sin GPU, con Intel Xeon a 2,1 GHz (4 núcleos) y 15 GB
  de RAM. Vulkan por software (Mesa llvmpipe, LLVM 20.1.2) en Xvfb, con Godot 4.7 stable oficial
  (5b4e0cb0f). Estos FPS **no representan un PC con tarjeta gráfica**: solo sirven para comparar entre
  estilos. Los valores útiles son el aumento de llamadas de dibujo (+18 %) y de triángulos (+21 %).
  El estilo anime sale más rápido aquí, probablemente porque el v13 activa el filtro pictórico
  Kuwahara, que es caro en CPU. Hace falta medir en un PC real.

### 4. Problemas detectados y soluciones

| Problema | Causa | Solución |
|---|---|---|
| El suelo nuevo no se veía y en su lugar aparecía el color del cielo | Godot toma como cara frontal el orden horario, y la malla se generó al revés | Se invirtió el orden de los triángulos. Una prueba comprueba las normales del suelo, las copas y las rocas |
| Al mediodía, el horizonte parecía un mar azul | El hemisferio inferior del cielo usaba el azul del horizonte | Bruma verde grisácea común a la niebla y al horizonte del suelo |
| Motas claras sobre las rocas | Microrrelieve de los escaneos con bandas de luz y sombra | Color plano, contorno solo en la silueta, y sustitución de los dos escaneos más ruidosos |
| Rocas pequeñas moteadas bajo los árboles | Sombra de las hojas recortadas sobre superficies pequeñas | Rocas nuevas fuera de la sombra de las copas |
| Suelo pastel y lavado | Paleta demasiado clara para la luz del atardecer | Paleta más oscura y saturación de 1,08 |

### 5. Limitaciones pendientes

- **Atardecer (16:30):** el suelo aún muestra manchas pastel rosadas y amarillas con la luz cálida, y se
  ve una franja clara donde termina el terreno. Hay que ajustarlo en la integración.
- **Masas de copa procedurales:** dan volumen y silueta, pero de cerca son superficies lisas. Para una
  copa con más carácter haría falta modelarla en Blender, con lóbulos esculpidos y borde de hojas.
- **Rocas:** las estilizadas tienen forma redondeada. Una roca de videojuego anime con planos más
  marcados también requiere modelado en Blender. Los dos escaneos sustituidos siguen sin usarse.
- **Versión de Godot:** pediste Godot 4.7.2. Este entorno tiene **Godot 4.7 stable** (la misma versión
  de todas las etapas anteriores), y las capturas se tomaron con esa versión.
- No se pudo medir el rendimiento en un PC con GPU real.

### 6. Cómo abrirla

Abre `res://scenes/pruebas/PruebaEntornoAnime.tscn` y ejecuta la escena (F6). Teclas: Tab cambia de
estilo, H cambia la hora, O activa o desactiva los contornos y Esc vuelve al menú. Los encuadres de la
Etapa C se usan en las capturas automáticas:

```
godot --path . res://scenes/pruebas/PruebaEntornoAnime.tscn -- --capturas=/ruta
godot --path . res://scenes/pruebas/PruebaEntornoAnime.tscn -- --medir=120
```

La relación completa de archivos está en [ARCHIVOS.md](ARCHIVOS.md).
