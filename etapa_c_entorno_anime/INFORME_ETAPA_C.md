# Etapa C · Entorno selvático anime: informe técnico

**Fecha:** 30 de octubre de 2026
**Base:** la copia de desarrollo de la Etapa B. La v13 entregada y su copia de seguridad siguen intactas.
**Estado:** terminada y en espera de revisión. La Etapa D no ha empezado.

Todo el trabajo está en una escena de prueba nueva, `scenes/pruebas/PruebaEntornoAnime.tscn`. El juego, el
mundo jugable y el laboratorio de la Etapa B no cambian. En la escena, la tecla Tab alterna entre el
estilo v13 original y el estilo anime para comparar.

## 1. Resultado por área

### Vegetación y árboles
- Se añadió un bosque de fondo con 2 árboles fijos y 14 repartidos con semilla fija. Usan las 8 variantes
  de `ArbolSelva` de la biblioteca, con tamaño y giro variados. El centro de la escena y el recorrido de la
  cámara quedan libres, para no tapar el espacio jugable.
- Cada árbol lleva 6 **masas de copa volumétricas**: esferas deformadas con lóbulos de ruido, en 6 tonos
  de verde, colocadas en el centro real de la copa (que se lee del GLB). La copa se lee como un volumen
  con bandas de luz y sombra, y no como hojas planas dispersas. Las hojas originales se mantienen alrededor
  para conservar el borde recortado.
- Las copas proyectan sombras grandes. Al mediodía dejan una sombra moteada sobre el suelo.

### Rocas y superficies naturales
- Las rocas escaneadas usan ahora un color plano propio, sin la foto, y la línea de contorno solo en la
  silueta. Así desaparecen las motas y las líneas interiores.
- La roca grande (`V_boulder_01_0`) y el conjunto con musgo (`V_rock_moss_set_01_0`) tienen
  **microrrelieve de escaneo**: con el sombreado por bandas, cada bulto se convierte en una mota de luz o
  sombra. En la escena de prueba se **sustituyen** por rocas estilizadas en el mismo sitio. Los escaneos
  originales no se modifican.
- Se añadieron 7 rocas estilizadas procedurales: relieve suave a dos escalas, base aplanada y musgo como
  masa de color en la parte superior.

### Terreno
- Se sustituyó el plano verde uniforme por una malla de 260 m con **parches de color por vértice**:
  musgo, hierba, hojarasca, tierra y zonas húmedas. Dentro de cada parche hay una variación de tono a dos
  escalas. No usa texturas fotográficas.
- El relieve es muy suave (unos 12 cm), así que el espacio jugable sigue leyéndose como plano.

### Cielo e iluminación
- El estilo anime tiene un **cielo propio**, con una paleta por hora (9, 13, 16:30, 18:12 y 21 h)
  interpolada a lo largo del ciclo. El v13 conserva su cielo de siempre.
- **Mediodía:** el cenit es azul saturado y no blanco. Se subieron la saturación (1,16) y el contraste
  (1,06) sin subir la exposición, para evitar los blancos quemados.
- **Bruma de selva:** la niebla y el horizonte del suelo comparten un color verde grisáceo. Así el final
  del terreno no se ve como un mar azul ni como una franja. De noche, la bruma se oscurece con el cielo.

### Materiales
Cada familia tiene una identidad propia:

| Material | Acabado |
|---|---|
| Madera (tablones, mimbre) | Color plano con la veta pintada (Etapa B) |
| Troncos (corteza) | Marrón rojizo, detalle pintado y musgo en masa |
| Roca | Gris neutro, sin foto, musgo arriba, contorno solo en la silueta |
| Tierra / suelo | Parches por vértice y bandas, sin textura |
| Copas | Masas en 6 verdes, con 3 bandas |
| Hojas y vegetación | Hojas recortadas con normales esféricas y translucidez (Etapa B) |

## 2. Capturas reales (Godot, Forward+)

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

## 3. Validación técnica

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

## 4. Problemas detectados y soluciones

| Problema | Causa | Solución |
|---|---|---|
| El suelo nuevo no se veía y en su lugar aparecía el color del cielo | Godot toma como cara frontal el orden horario, y la malla se generó al revés | Se invirtió el orden de los triángulos. Una prueba comprueba las normales del suelo, las copas y las rocas |
| Al mediodía, el horizonte parecía un mar azul | El hemisferio inferior del cielo usaba el azul del horizonte | Bruma verde grisácea común a la niebla y al horizonte del suelo |
| Motas claras sobre las rocas | Microrrelieve de los escaneos con bandas de luz y sombra | Color plano, contorno solo en la silueta, y sustitución de los dos escaneos más ruidosos |
| Rocas pequeñas moteadas bajo los árboles | Sombra de las hojas recortadas sobre superficies pequeñas | Rocas nuevas fuera de la sombra de las copas |
| Suelo pastel y lavado | Paleta demasiado clara para la luz del atardecer | Paleta más oscura y saturación de 1,08 |

## 5. Limitaciones pendientes

- **Atardecer (16:30):** el suelo aún muestra manchas pastel rosadas y amarillas con la luz cálida, y se
  ve una franja clara donde termina el terreno. Hay que ajustarlo en la integración.
- **Masas de copa procedurales:** dan volumen y silueta, pero de cerca son superficies lisas. Para una
  copa con más carácter haría falta modelarla en Blender, con lóbulos esculpidos y borde de hojas.
- **Rocas:** las estilizadas tienen forma redondeada. Una roca de videojuego anime con planos más
  marcados también requiere modelado en Blender. Los dos escaneos sustituidos siguen sin usarse.
- **Versión de Godot:** pediste Godot 4.7.2. Este entorno tiene **Godot 4.7 stable** (la misma versión
  de todas las etapas anteriores), y las capturas se tomaron con esa versión.
- No se pudo medir el rendimiento en un PC con GPU real.

## 6. Cómo abrirla

Abre `res://scenes/pruebas/PruebaEntornoAnime.tscn` y ejecuta la escena (F6). Teclas: Tab cambia de
estilo, H cambia la hora, O activa o desactiva los contornos y Esc vuelve al menú. Los encuadres de la
Etapa C se usan en las capturas automáticas:

```
godot --path . res://scenes/pruebas/PruebaEntornoAnime.tscn -- --capturas=/ruta
godot --path . res://scenes/pruebas/PruebaEntornoAnime.tscn -- --medir=120
```

La relación completa de archivos está en [ARCHIVOS.md](ARCHIVOS.md).
