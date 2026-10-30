# Punto de control · C3 antes de la validación y el pulido

**Fecha:** 30 de octubre de 2026

Este commit marca el estado de la C3 tal como se entregó (commit `bf3569a`), antes de empezar la
validación con el personaje en movimiento y el pulido. Para volver a este estado:

```
git checkout <commit de este punto de control> -- etapa_c_entorno_anime/
```

Estado comprobado antes de cambiar nada (Godot 4.7.2):
- La escena `res://scenes/pruebas/PruebaEntornoAnimeC3.tscn` carga sin errores.
- Pruebas en modo `anime`: 80 de 80 correctas. La suite completa de la entrega C3 dio 317 de 317.
- Archivos de la C3 en `proyecto/`:
  - `scenes/pruebas/PruebaEntornoAnimeC3.tscn`
  - `scripts/anime/prueba_entorno_c3.gd`
  - `scripts/anime/selva_c3.gd`
  - `assets/materials/anime/anime_suelo_selva_c3.gdshader`
  - `assets/materials/anime/anime_luciernaga.gdshader`
  - `tests/entorno_c3_tests.gd`
- Proyecto completo de este estado: `selva/avance/anime_etapaC/RPG_Godot47_Prototype_etapaC3_entorno_anime.zip`
  en los archivos del proyecto (223 MB, no cabe en GitHub).
