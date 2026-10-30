# Relación de archivos · Etapa C

Las rutas de `proyecto/` son las mismas que dentro del proyecto Godot (`res://`).

## Nuevos en la Etapa C
| Archivo | Qué es |
|---|---|
| `proyecto/scenes/pruebas/PruebaEntornoAnime.tscn` | Escena de prueba del entorno |
| `proyecto/scripts/anime/prueba_entorno.gd` | Montaje de la escena, cielo por hora, encuadres, capturas y medición |
| `proyecto/scripts/anime/entorno_selva.gd` | Suelo con parches, masas de copa y rocas procedurales |
| `proyecto/assets/materials/anime/anime_terreno.gdshader` | Shader anime del suelo |
| `proyecto/tests/entorno_anime_tests.gd` | 10 pruebas nuevas |

## Modificados en la Etapa C
| Archivo | Cambio |
|---|---|
| `proyecto/tests/e2e_director.gd` | Ejecuta las pruebas del entorno en los modos all, unit y anime |
| `proyecto/CHANGELOG.md` | Nueva entrada de la Etapa C |

## Incluidos porque la escena los necesita (de la Etapa B, sin cambios en esta etapa)
`anime_luz.gdshaderinc`, `anime_personaje`, `anime_contorno`, `anime_entorno`, `anime_follaje`,
`anime_contorno_post` (.gdshader), `estilo_anime.gd`, `prueba_anime.gd`, `PruebaAnime.tscn`,
`anime_tests.gd`, `ajustes.gd`, `cinematic_look.gd`, `options_panel.gd` y `main_menu.gd`.

## Recursos originales no modificados
Ningún shader, GLB ni material del v13 se ha modificado. La prueba «Recursos originales v13 intactos»
compara su MD5 con la v13 entregada. Los dos escaneos de roca que se sustituyen en la escena de prueba
solo se ocultan en esa escena: los archivos siguen igual.

## Otros archivos de esta carpeta
- `capturas/`: 11 capturas reales de Forward+ (8 del estilo anime y 3 del v13).
- `comparaciones/`: 3 láminas v13 | anime hechas con esas capturas, sin retoques.
- `pruebas/`: resultado de las 276 pruebas, consola de Forward+ y medición de rendimiento.
- `etapa_c_entorno_anime.zip`: todo lo anterior en un ZIP.
