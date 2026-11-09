# Solarus para PS4

Port no oficial del motor **Solarus** (v2.1.4) a PlayStation 4 liberada
(GoldHEN), con el objetivo de jugar **Tombwater** en la consola.

- Motor: [Solarus](https://gitlab.com/solarus-games/solarus) 2.1.4, C++17,
  renderizador GLES 2.0 oficial (`SOLARUS_GL_ES=ON`) — el camino que el
  Piglet de PS4 entiende — y Lua 5.1 (`SOLARUS_USE_LUAJIT=OFF`, sin JIT).
- SDL 2.0.18 del fork **PacBrew/SDL, rama `ps4`** (driver de vídeo Piglet,
  audio y mando de PS4).
- OpenAL no existe para PS4: se usa **mojoAL** vendido en este repo (era
  Switch, API SDL2, probado en consola).
- El paquete `.pkg` contiene **solo el motor**: los datos de la quest
  (Tombwater, de la copia de Steam de cada uno, o su demo gratuita) se
  suben por FTP a `/data/solarus/tombwater/`.

## Estado

Fase 0: esqueleto del repo de build y primer build en GitHub Actions
(motor `solarus-run` + prueba de humo GL). Sin probar en consola todavía.

## Cómo se construye

Todo se compila en GitHub Actions (`windows-latest`, solo manual,
`workflow_dispatch`), con OpenOrbis 0.5.4 + LLVM 18.1.8. Pasos:

```bash
bash scripts/prepare-sources.sh   # clona Solarus v2.1.4 (GitLab) a ../solarus
bash build-deps.sh                # construye las dependencias en prefix/
bash configure.sh                 # configura Solarus para PS4
cmake --build build --target solarus-run --parallel 4
bash package.sh                   # genera out/*.pkg
```

Detalles, decisiones y riesgos conocidos: ver `BUILD.md`.
Instalación y prueba en consola: ver `docs/INSTALL.md`.

## Estructura

| Ruta | Qué es |
| --- | --- |
| `.github/workflows/build-ps4.yml` | workflow de GitHub Actions |
| `scripts/prepare-sources.sh` | clona Solarus v2.1.4 |
| `build-deps.sh` | construye zlib, libpng, libjpeg-turbo, freetype, ogg, vorbis, libmodplug, glm, libsamplerate, SDL 2.0.18 (ps4), SDL2_image, SDL2_ttf, PhysFS, Lua 5.1.5, mojoAL |
| `configure.sh` | configura Solarus para PS4 (rutas `/data/solarus/`) |
| `package.sh` | empaqueta el `.elf` en `.pkg` |
| `cmake/` | toolchain PS4 (OpenOrbis + LLVM, adaptado del port SoH) |
| `compat/include/` | `ps4_fixups.h` y `sys/endian.h` del port SoH |
| `mojoal/` | mojoAL vendido (era Switch, SDL2) |
| `lua-cmake/`, `mojoal-cmake/`, `zlib-cmake/` | wrappers CMake para libs sin CMakeLists |
| `tests/gl-smoke/` | prueba mínima SDL + GLES2 (prueba el camino Piglet) |
| `pkg-static/` | icono del `.pkg` (logo de Solarus, 512×512) |
| `docs/INSTALL.md` | instalación y prueba en la PS4 |

## Licencias

Solarus es GPLv3; este repo de build es MIT (ver `LICENSE`).
mojoAL es zlib/libpng license (ver `mojoal/LICENSE.txt`).
Los módulos Piglet de Sony **no** se distribuyen aquí: cada uno los extrae
de su propia consola (ver `docs/INSTALL.md`).
