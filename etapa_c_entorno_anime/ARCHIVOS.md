# Relación de archivos · Etapa C

Las rutas de `proyecto/` son las mismas que dentro del proyecto Godot (`res://`).

## Revisión C3

### Nuevos en la C3
| Archivo | Qué es |
|---|---|
| `proyecto/scenes/pruebas/PruebaEntornoAnimeC3.tscn` | Escena de prueba C3 (aislada) |
| `proyecto/scripts/anime/prueba_entorno_c3.gd` | `PruebaEntornoC3 extends PruebaEntornoC2`: bosque de 7 especies en MultiMesh, primer plano, rocas, raíces, lianas, noche, capturas |
| `proyecto/scripts/anime/selva_c3.gd` | Especies nuevas (monumental, pisos, cecropia, inclinado), raíces, luciérnagas, material de suelo C3 |
| `proyecto/assets/materials/anime/anime_suelo_selva_c3.gdshader` | Suelo C3 (rocas, roderas, piedrecillas, musgo, luna) |
| `proyecto/assets/materials/anime/anime_luciernaga.gdshader` | Luciérnagas |
| `proyecto/tests/entorno_c3_tests.gd` | 21 pruebas nuevas |

### Modificados en la C3
| Archivo | Cambio |
|---|---|
| `proyecto/tests/e2e_director.gd` | Ejecuta también las pruebas C3 |
| `proyecto/CHANGELOG.md` | Entrada de la revisión C3 |

Ningún archivo de la C2, la C1, la Etapa B ni el v13 se ha modificado en la C3.

### Carpetas nuevas de la C3
- `capturas_c3/`: 17 capturas reales de Godot 4.7.2 (Forward+).
- `comparaciones_c3/`: 12 láminas C2 | C3 con el mismo encuadre y la misma hora, y la hoja del ciclo día-noche C3.
- `pruebas_c3/`: 317 pruebas, consola de Forward+ y medición.

Las carpetas de la C1 y la C2 se conservan sin cambios.

---

## Revisión C2

### Nuevos en la C2
| Archivo | Qué es |
|---|---|
| `proyecto/scenes/pruebas/PruebaEntornoAnimeC2.tscn` | Escena de prueba C2 (aislada) |
| `proyecto/scripts/anime/prueba_entorno_c2.gd` | Montaje del bosque, sotobosque, rocas, luz por hora, encuadres, comparación v13, capturas y medición |
| `proyecto/scripts/anime/selva_c2.gd` | Árboles por especie (ceiba, redonda, joven), racimos de hojas, rocas facetadas, suelo, selva lejana |
| `proyecto/assets/materials/anime/anime_copa.gdshader` | Shader de las copas (racimos de hojas) |
| `proyecto/assets/materials/anime/anime_suelo_selva.gdshader` | Shader del suelo por zonas |
| `proyecto/assets/anime/selva_c2/racimo_hojas.png` (+ `.import`) | Atlas de 4 racimos de hojas |
| `proyecto/tools/c2/generar_racimos.py` | Script que genera ese atlas |
| `proyecto/tests/entorno_c2_tests.gd` | 20 pruebas nuevas |

### Modificados en la C2
| Archivo | Cambio |
|---|---|
| `proyecto/tests/e2e_director.gd` | Ejecuta también las pruebas C2 (modos all, unit y anime) |
| `proyecto/CHANGELOG.md` | Entrada de la revisión C2 |

Ningún archivo de la Etapa B, de la escena C1 ni de la v13 se ha modificado en la C2.

### Carpetas nuevas de la C2
- `capturas_c2/`: 28 capturas reales de Godot 4.7.2 (Forward+). Hay 7 encuadres al mediodía en anime y
  v13, y el plano general a 7 horas más en los dos estilos.
- `comparaciones_c2/`: 7 láminas v13 | anime al mediodía y 2 hojas del ciclo día-noche, hechas con esas
  capturas y sin retoques.
- `pruebas_c2/`: resultado de las 296 pruebas, consola de Forward+ y medición con 4.7.2.

Las carpetas `capturas/`, `comparaciones/` y `pruebas/` son de la C1 y se conservan sin cambios.

---

## Versión C1


### Nuevos en la Etapa C
| Archivo | Qué es |
|---|---|
| `proyecto/scenes/pruebas/PruebaEntornoAnime.tscn` | Escena de prueba del entorno |
| `proyecto/scripts/anime/prueba_entorno.gd` | Montaje de la escena, cielo por hora, encuadres, capturas y medición |
| `proyecto/scripts/anime/entorno_selva.gd` | Suelo con parches, masas de copa y rocas procedurales |
| `proyecto/assets/materials/anime/anime_terreno.gdshader` | Shader anime del suelo |
| `proyecto/tests/entorno_anime_tests.gd` | 10 pruebas nuevas |

### Modificados en la Etapa C
| Archivo | Cambio |
|---|---|
| `proyecto/tests/e2e_director.gd` | Ejecuta las pruebas del entorno en los modos all, unit y anime |
| `proyecto/CHANGELOG.md` | Nueva entrada de la Etapa C |

### Incluidos porque la escena los necesita (de la Etapa B, sin cambios en esta etapa)
`anime_luz.gdshaderinc`, `anime_personaje`, `anime_contorno`, `anime_entorno`, `anime_follaje`,
`anime_contorno_post` (.gdshader), `estilo_anime.gd`, `prueba_anime.gd`, `PruebaAnime.tscn`,
`anime_tests.gd`, `ajustes.gd`, `cinematic_look.gd`, `options_panel.gd` y `main_menu.gd`.

### Recursos originales no modificados
Ningún shader, GLB ni material del v13 se ha modificado. La prueba «Recursos originales v13 intactos»
compara su MD5 con la v13 entregada. Los dos escaneos de roca que se sustituyen en la escena de prueba
solo se ocultan en esa escena: los archivos siguen igual.

### Otros archivos de esta carpeta
- `capturas/`: 11 capturas reales de Forward+ (8 del estilo anime y 3 del v13).
- `comparaciones/`: 3 láminas v13 | anime hechas con esas capturas, sin retoques.
- `pruebas/`: resultado de las 276 pruebas, consola de Forward+ y medición de rendimiento.
- `etapa_c_entorno_anime.zip`: todo lo anterior en un ZIP.
